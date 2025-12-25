//
//  ResultView.swift
//  PulseControl
//
//  Created by Aya on 2025-12-16.
//

import SwiftUI

struct ResultView: View {
    let bpm: Int

    private var category: PulseCategory {
        PulseCategory.from(bpm: bpm)
    }

    var body: some View {
        VStack(spacing: 20) {

            Spacer()

            Text("Your measurement is")
                .font(.title)
                .fontWeight(.bold)

            Text("BPM: \(bpm)")
                .font(.system(size: 40, weight: .bold))

            // Category title (all visual logic comes from PulseCategory)
            Text(category.title)
                .font(category.fontSize)
                .fontWeight(category.fontWeight)
                .foregroundColor(category.color)

            Text(category.message)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            // Buttons depending on category
            VStack(spacing: 14) {

                // Measure again (always available)
                NavigationLink {
                    MeasureView()
                } label: {
                    PrimaryButton(title: "Measure Again")
                }

                // Secondary action
                switch category {
                case .normal:
                    EmptyView()

                case .low:
                    NavigationLink {
                        ExerciseView()
                    } label: {
                        SecondaryButton(title: "Go to Exercise")
                    }

                case .high:
                    NavigationLink {
                        BreathingListView()
                    } label: {
                        SecondaryButton(title: "Breathing Exercises")
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Pulse Category

enum PulseCategory {
    case low, normal, high

    static func from(bpm: Int) -> PulseCategory {
        if bpm < 60 { return .low }
        if bpm <= 100 { return .normal }
        return .high
    }

    var title: String {
        switch self {
        case .low: return "Low pulse"
        case .normal: return "Normal pulse"
        case .high: return "High pulse"
        }
    }

    var message: String {
        switch self {
        case .low:
            return "Your pulse is low. A short burst of movement can help raise it"
        case .normal:
            return "Your pulse looks good \n Keep it up!"
        case .high:
            return "Your pulse is high. A breathing exercise can help you calm down"
        }
    }

    // Visual logic (shared, clean)
    var color: Color {
        switch self {
        case .normal:
            return .green
        case .low, .high:
            return .red
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .normal:
            return .semibold
        case .low, .high:
            return .bold
        }
    }

    var fontSize: Font {
        switch self {
        case .low:
            return .title2
        case .normal, .high:
            return .headline
        }
    }
}

// MARK: - Reusable buttons (same style as Home)

struct PrimaryButton: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(14)
    }
}

struct SecondaryButton: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.15))
            .foregroundColor(.blue)
            .cornerRadius(14)
    }
}

#Preview {
    NavigationStack {
        ResultView(bpm: 59)
    }
}

