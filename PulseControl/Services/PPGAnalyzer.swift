//
//  PPGAnalyzer.swift
//  PulseControl
//
//  Created by Aya on 2025-12-16.
//

import Foundation
import QuartzCore

final class PPGAnalyzer {

    // Called when we have a stable BPM estimate to show in the UI
    var onBPMUpdate: ((Int) -> Void)?

    // Debug prints to help tune thresholds and verify detection
    private let debug = true

    // Measurement timing and stability gating
    private var measurementStartTime: TimeInterval?
    private let warmUpTime: TimeInterval = 3.0            // ignore first seconds while signal settles
    private let stabilizationTime: TimeInterval = 5.0     // require some time before trusting BPM
    private let minPeaksForStability = 3                  // minimum number of peaks before updating UI

    // Unused (kept for now, could be removed later if not needed)
    private let fastAlpha: Double = 0.5
    private let slowBeta: Double = 0.05
    private var fastEWMA: Double?
    private var slowEWMA: Double?
    private let crossHysteresis: Double = 0.05
    private var wasAbove = false
    private var prevFast: Double?
    private var prevSlow: Double?

    // Peak detection state
    private var peakTimestamps: [TimeInterval] = []       // unused (kept for now)
    private let minPeakInterval: TimeInterval = 0.55      // reject peaks that are too close (noise/double count)
    private var isStable = false
    private var acPeakTimestamps: [TimeInterval] = []     // timestamps for detected AC peaks

    // Baseline tracking (DC removal) to get AC signal
    private var baseline: Double = 0
    private let baselineAlpha: Double = 0.02              // baseline smoothing speed
    private var lastAC: Double = 0                        // previous AC in the 3-point window
    private var lastPeakTime: TimeInterval = 0
    private var acThreshold: Double = 0.2                 // minimum AC amplitude to count as a real peak
    private var prevAC: Double = 0                        // previous-previous AC in the 3-point window
    private var lastACTime: TimeInterval = 0              // timestamp corresponding to lastAC

    // BPM smoothing (reduce jitter in UI)
    private var bpmValues: [Double] = []
    private let bpmWindowSize = 5

    // Optional: store raw samples for debugging prints
    private var sValues: [Double] = []

    func startMeasurement(startTime: TimeInterval) {
        measurementStartTime = startTime

        // Reset all measurement state
        acPeakTimestamps.removeAll()
        bpmValues.removeAll()
        sValues.removeAll()

        baseline = 0
        prevAC = 0
        lastAC = 0
        lastACTime = 0
        lastPeakTime = 0
        isStable = false
    }

    func stopMeasurement() {
        measurementStartTime = nil
    }

    // S(n) is the mean red value from the ROI (one value per frame)
    func processSample(_ s: Double, timestamp now: TimeInterval) {
        guard let start = measurementStartTime else { return }

        // Keep raw sample history (debug only)
        sValues.append(s)

        /// 1) DC removal: track a slow baseline and subtract it -> AC component
        if baseline == 0 { baseline = s } // initialize baseline on first sample
        baseline = (1.0 - baselineAlpha) * baseline + baselineAlpha * s
        let ac = s - baseline

        /// 2) Peak detection on AC using a 3-point local maximum
        // We need at least 2 stored points (prevAC + lastAC) before we can detect a local max
        if lastACTime == 0 {
            prevAC = ac
            lastAC = ac
            lastACTime = now
            return
        }

        let elapsed = now - start
        let allowPeaks = elapsed >= warmUpTime

        // Count a peak if lastAC is greater than both neighbors and above threshold
        let isPeak = (lastAC > prevAC) && (lastAC > ac) && (lastAC > acThreshold)

        // Helpful debug print to see if threshold is too high/low
        if debug && allowPeaks && sValues.count % 30 == 0 {
            print("allowPeaks:", allowPeaks, "prevAC:", prevAC, "lastAC:", lastAC, "ac:", ac, "thr:", acThreshold)
        }

        // Enforce minimum time between peaks to avoid double counting
        if allowPeaks && isPeak && (lastACTime - lastPeakTime) >= minPeakInterval {

            // Save the timestamp for the peak (we use lastACTime for lastAC)
            acPeakTimestamps.append(lastACTime)
            lastPeakTime = lastACTime

            if debug {
                let dt = acPeakTimestamps.count >= 2
                ? acPeakTimestamps.last! - acPeakTimestamps[acPeakTimestamps.count - 2]
                : -1
                print("PEAK(AC) dt:", dt, "peakAC:", lastAC, "acNow:", ac)
            }

            /// 3) Only allow UI updates after enough time + enough peaks
            let elapsed = now - start
            if !isStable,
               elapsed >= stabilizationTime,
               acPeakTimestamps.count >= minPeaksForStability {
                isStable = true
            }

            /// 4) Update BPM if stable
            if isStable {
                calculateBPM()
            }
        }

        // Shift the 3-point window forward
        prevAC = lastAC
        lastAC = ac
        lastACTime = now

        // Debug print of raw sample and AC/baseline occasionally
        if debug && sValues.count % 30 == 0 {
            print("S(n):", s)
            print("AC:", ac, "baseline:", baseline)
        }
    }

    private func calculateBPM() {
        guard acPeakTimestamps.count >= 2 else { return }

        // Convert peak timestamps -> intervals between beats
        let intervals = zip(acPeakTimestamps.dropFirst(), acPeakTimestamps)
            .map { $0 - $1 }
            .filter { $0 >= 0.55 && $0 <= 1.5 }

        guard intervals.count >= 2 else { return }

        // Use a small recent window and take the median for robustness
        let lastN = Array(intervals.suffix(5)).sorted()

        // Skip UI updates if intervals vary too much (likely noise/missed peaks)
        guard intervalsAreStable(lastN) else {
            if debug { print("Intervals not stable, skipping UI update:", lastN) }
            return
        }

        let medianInterval = lastN[lastN.count / 2]

        if debug {
            let avgInterval = lastN.reduce(0, +) / Double(lastN.count)
            print("Intervals(lastN):", lastN, "avg:", avgInterval, "median:", medianInterval)
        }

        // Convert interval (seconds/beat) -> BPM
        let bpm = 60.0 / medianInterval

        // Smooth BPM to reduce flicker in UI
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

        // Allow up to ~30% spread around the median
        return (maxV - minV) / med < 0.30
    }
}
