//
//  BreathingExerciseModel.swift
//  PulseControl
//
//  Created by Aya on 2025-12-24.
//

import Foundation

struct BreathingExerciseModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let inhale: Int
    let hold: Int?
    let exhale: Int
    let holdAfterExhale: Int?
    let durationSeconds: Int
}
