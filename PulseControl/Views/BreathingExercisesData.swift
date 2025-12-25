//
//  BreathingExercisesData.swift
//  PulseControl
//
//  Created by Aya on 2025-12-24.
//
import Foundation

let breathingExercises: [BreathingExerciseModel] = [

    BreathingExerciseModel(
        title: "Box Breathing",
        subtitle: "4–4–4–4 structured breathing",
        inhale: 4,
        hold: 4,
        exhale: 4,
        holdAfterExhale: 4,
        durationSeconds: 120
    ),

    BreathingExerciseModel(
        title: "4-7-8 Breathing",
        subtitle: "Deep calming breathing",
        inhale: 4,
        hold: 7,
        exhale: 8,
        holdAfterExhale: nil,
        durationSeconds: 120
    ),

    BreathingExerciseModel(
        title: "Extended Exhale",
        subtitle: "Gentle breathing with longer exhale",
        inhale: 4,
        hold: nil,
        exhale: 6,
        holdAfterExhale: nil,
        durationSeconds: 120
    )
]
