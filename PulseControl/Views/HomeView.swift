//
//  HomeView.swift
//  PulseControl
//
//  Created by Aya on 2025-12-16.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 32) {

            Spacer()

            // App name – higher up
                 Text("Pulse Control")
                     .font(.largeTitle)
                     .fontWeight(.bold)
                     .padding(.top, 40)

            // Short description
            Text("Take control of your pulse for better well-being")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Buttons
            VStack(spacing: 16) {

                NavigationLink {
                    MeasureView()
                } label: {
                    Text("Measure Pulse")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                NavigationLink {
                    BreathingListView()
                } label: {
                    Text("Breathing Exercises")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(Color.blue)
                        .cornerRadius(12)
                }
                
                NavigationLink{
                    ExerciseView()
                }label: {
                    Text("Quick Movement")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}



#Preview {
    HomeView()
}
