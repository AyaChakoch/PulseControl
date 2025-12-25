//
//  BreathingListView.swift
//  PulseControl
//
//  Created by Aya on 2025-12-24.
//

import SwiftUI

struct BreathingListView: View {

    var body: some View {
        VStack(spacing: 20) {

            Text("Breathing Exercises")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)

            VStack(spacing: 14) {
                ForEach(breathingExercises) { exercise in
                    NavigationLink {
                        BreathingExerciseView(exercise: exercise)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.title)
                                .font(.headline)

                            Text(exercise.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BreathingListView()
    }
}
