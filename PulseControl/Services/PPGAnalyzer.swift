//
//  PPGAnalyzer.swift
//  PulseControl
//
//  Created by Aya on 2025-12-16.
//

import Foundation
import QuartzCore

final class PPGAnalyzer {

    // ===== callback =====
    var onBPMUpdate: ((Int) -> Void)?

    // ===== Debug =====
    private let debug = true

    // ===== Timing =====
    private var measurementStartTime: TimeInterval?
    private let warmUpTime: TimeInterval = 5.0
    private let stabilizationTime: TimeInterval = 5.0
    private let minPeaksForStability = 2

    // ===== Two EWMAs (teacher's method) =====
    private let fastAlpha: Double = 0.5   // fast EWMA (α)
    private let slowBeta: Double = 0.05   // slow EWMA (β)

    private var fastEWMA: Double?
    private var slowEWMA: Double?
    
    private let crossHysteresis: Double = 0.05
    
    private var wasAbove = false


    private var prevFast: Double?
    private var prevSlow: Double?

    // ===== Peak detection =====
    private var peakTimestamps: [TimeInterval] = []
    private let minPeakInterval: TimeInterval = 0.45
    private var isStable = false

    // ===== BPM smoothing =====
    private var bpmValues: [Double] = []
    private let bpmWindowSize = 5

    // (optional) keep raw for debug prints
    private var sValues: [Double] = []

    func startMeasurement(startTime: TimeInterval) {
        measurementStartTime = startTime

        // reset state
        fastEWMA = nil
        slowEWMA = nil
        prevFast = nil
        prevSlow = nil
        

        peakTimestamps.removeAll()
        bpmValues.removeAll()
        sValues.removeAll()
        
        wasAbove = false
        isStable = false
    }

    func stopMeasurement() {
        measurementStartTime = nil
    }

    /// S(n) = redAvg (ROI mean). Call this for every frame
    func processSample(_ s: Double, timestamp now: TimeInterval) {
        guard let start = measurementStartTime else { return }

        sValues.append(s)

        // --- 1) Update two EWMAs ---
        if fastEWMA == nil || slowEWMA == nil {
            // initialize first sample
            fastEWMA = s
            slowEWMA = s
            prevFast = fastEWMA
            prevSlow = slowEWMA
            return
        }

        // store previous values for crossing check
        let pf = fastEWMA!
        let ps = slowEWMA!
        prevFast = pf
        prevSlow = ps

        // EWMA formulas:
        // F_fast(n) = α*F_fast(n-1) + (1-α)*S(n)
        // F_slow(n) = β*F_slow(n-1) + (1-β)*S(n)
        fastEWMA = fastAlpha * s + (1.0 - fastAlpha) * pf
        slowEWMA = slowBeta  * s + (1.0 - slowBeta)  * ps

        let f = fastEWMA!
        let sl = slowEWMA!

        // --- 2) Warm-up (ignore peaks early) ---
        let elapsed = now - start
        let allowPeaks = elapsed >= warmUpTime

        if allowPeaks, let prevF = prevFast, let prevS = prevSlow {
            // --- 3) Peak when FAST crosses from above SLOW to below SLOW ---
            
            let prevDiff = prevF - prevS
            let diff = f - sl

            if debug && sValues.count % 30 == 0 {
                print("diff(fast-slow):", diff)
            }

            // 1) latch: minns att vi varit tydligt över slow
            if diff > crossHysteresis {
                wasAbove = true
            }

            // 2) peak när vi sen går tydligt under slow
            let crossedDown = wasAbove && diff < -crossHysteresis

            if crossedDown {
                wasAbove = false
                // enforce min interval between peaks
                var validPeak = true
                if let last = peakTimestamps.last, now - last < minPeakInterval {
                    validPeak = false
                }
                if validPeak {
                    peakTimestamps.append(now)

                    if debug, peakTimestamps.count >= 2 {
                        let dt = peakTimestamps.last! - peakTimestamps[peakTimestamps.count - 2]
                        print("PEAK(cross) dt:", dt, "fast:", f, "slow:", sl)
                    }

                    // --- 4) Stability gate (same idea as before) ---
                    if !isStable,
                       elapsed >= stabilizationTime,
                       peakTimestamps.count >= minPeaksForStability {
                        isStable = true
                    }

                    if isStable {
                        calculateBPM()
                    }
                }
            }
        }

        // Debug prints
        if debug && sValues.count % 30 == 0 {
            print("S(n):", s, "fast:", fastEWMA ?? -1, "slow:", slowEWMA ?? -1)
        }
    }

    // ===== BPM calculation (unchanged) =====
    private func calculateBPM() {
        guard peakTimestamps.count >= 2 else { return }

        let intervals = zip(peakTimestamps.dropFirst(), peakTimestamps)
            .map { $0 - $1 }
            .filter { $0 >= 0.45 && $0 <= 1.5 }

        guard intervals.count >= 2 else { return }

        let lastN = Array(intervals.suffix(5)).sorted()
        
        //guard intervalsAreStable(lastN) else {
         //   if debug { print("Intervals not stable, skipping UI update:", lastN) }
         //   return
       // }

        
        let medianInterval = lastN[lastN.count / 2]

        if debug {
            let avgInterval = lastN.reduce(0, +) / Double(lastN.count)
            print("Intervals(lastN):", lastN, "avg:", avgInterval, "median:", medianInterval)
        }

        let bpm = 60.0 / medianInterval

        bpmValues.append(bpm)
        if bpmValues.count > bpmWindowSize {
            bpmValues.removeFirst()
        }

        let smoothBPM = bpmValues.reduce(0, +) / Double(bpmValues.count)

        if debug {
            print("Raw BPM:", Int(bpm), "→ Smoothed BPM:", Int(smoothBPM))
        }

        let smoothInt = Int(smoothBPM.rounded())
        onBPMUpdate?(smoothInt)
        print("UI UPDATE BPM:", smoothInt)
    }
    
    private func intervalsAreStable(_ xs: [Double]) -> Bool {
        guard xs.count >= 3 else { return false }
        let minV = xs.min()!
        let maxV = xs.max()!
        let med = xs.sorted()[xs.count / 2]
        if med <= 0 { return false }

        // Tillåt max ~15% variation
        return (maxV - minV) / med < 0.15
    }


    
    
    
}

