//
//  PPGCameraService.swift
//  PulseControl
//
//  Created by Aya on 2025-12-16.
//

import Foundation
import AVFoundation
import QuartzCore

final class PPGCameraService: NSObject {
    var onMeasurementFinished: (() -> Void)?


    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.queue")
    private var isMeasuring = false

    private var measurementStartTime: TimeInterval?
    private let measurementDuration: TimeInterval = 30.0

    var onBPMUpdate: ((Int) -> Void)? {
        didSet { analyzer.onBPMUpdate = onBPMUpdate }
    }

    private let analyzer = PPGAnalyzer()

    // Camera config
    private var videoDevice: AVCaptureDevice?
    private let roiHalfSize: Int = 12
    private let lockDelay: TimeInterval = 0.8
    private var didLockCamera = false
    private let preMeasureDelay: TimeInterval = 1.5


    private let debug = true
    private var isStarting = false


    func start() {
        queue.async {
            if self.session.isRunning { return }
            self.session.beginConfiguration()

            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }

            self.session.sessionPreset = .medium

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { return }

            self.videoDevice = device
            self.session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
            ]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.queue)

            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                
            }
        }
    }


    func startMeasuring() {
        queue.async {
    
            guard !self.isMeasuring && !self.isStarting else { return }

            self.isStarting = true
            
            self.enableTorch(true)
            self.didLockCamera = false

            // Vänta lite innan vi sätter igång mätningen
            self.queue.asyncAfter(deadline: .now() + self.preMeasureDelay) {
                
                guard self.isStarting else { return }
                self.isStarting = false
                
                self.isMeasuring = true

                let start = CACurrentMediaTime()
                self.measurementStartTime = start

                self.analyzer.startMeasurement(startTime: start)

                // Lås kamera en stund efter att mätningen startat
                self.queue.asyncAfter(deadline: .now() + self.lockDelay) {
                    self.lockCameraForMeasurement()
                }
            }
        }
    }

    

    func stopMeasuring() {
        queue.async {
            self.isStarting = false

            self.measurementStartTime = nil
            self.analyzer.stopMeasurement()

            guard self.isMeasuring else {
                self.enableTorch(false)
                return
            }

            self.isMeasuring = false
            self.enableTorch(false)
            self.unlockCameraAfterMeasurement()

            print("Measurement finished after 30 seconds")
            self.onMeasurementFinished?()
        }

    }

    

    // Torch
    private func enableTorch(_ on: Bool) {
        guard
            let device = self.videoDevice ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            device.hasTorch
        else { return }

        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    private func lockCameraForMeasurement() {
        guard isMeasuring, !didLockCamera else { return }
        guard let device = self.videoDevice else { return }

        do {
            try device.lockForConfiguration()

            if device.isExposureModeSupported(.locked) {
                device.exposureMode = .locked
            }
            if device.isWhiteBalanceModeSupported(.locked) {
                device.whiteBalanceMode = .locked
            }
            if device.isFocusModeSupported(.locked) {
                device.focusMode = .locked
            }

            device.unlockForConfiguration()
            didLockCamera = true

            if debug {
                print("Camera locked (exposure/whiteBalance/focus).")
            }
        } catch {
            if debug {
                print("Could not lock camera:", error.localizedDescription)
            }
        }
    }

    
    
    private func unlockCameraAfterMeasurement() {
        guard let device = self.videoDevice else { return }
        do {
            try device.lockForConfiguration()

            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            device.unlockForConfiguration()
        } catch {
           
        }
    }
}

extension PPGCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isMeasuring else { return }
        guard let start = measurementStartTime else { return }

        let now = CACurrentMediaTime()
        let elapsed = now - start

        if elapsed >= measurementDuration {
            stopMeasuring()
            return
        }

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return }
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        // ROI-average
        let centerX = width / 2
        let centerY = height / 2

        let x0 = max(0, centerX - roiHalfSize)
        let x1 = min(width - 1, centerX + roiHalfSize)
        let y0 = max(0, centerY - roiHalfSize)
        let y1 = min(height - 1, centerY + roiHalfSize)

        var sumRed: Double = 0
        var count: Double = 0

        for y in y0...y1 {
            let rowBase = y * bytesPerRow
            for x in x0...x1 {
                let offset = rowBase + x * 4
                let red = Double(buffer[offset + 2]) // BGRA → R
                sumRed += red
                count += 1
            }
        }

        let redAvg = (count > 0) ? (sumRed / count) : 0

        // Send to analyzer
        analyzer.processSample(redAvg, timestamp: now)
    }
    
}



