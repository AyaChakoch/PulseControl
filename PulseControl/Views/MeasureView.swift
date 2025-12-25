//
//  MeasureView.swift
//  PulseControl
//
//  Created by Aya on 2025-12-16.
//
import SwiftUI

struct MeasureView: View {

    @StateObject private var viewModel = PulseViewModel()

    @State private var isMeasuring = false
    @State private var remainingTime = 30
    @State private var timer: Timer?
    @State private var navigateToResult = false
    @State private var showInstructions = false
    @State private var measurementFailed = false


    var body: some View {
        VStack(spacing: 24) {

            
            Spacer()

            // Title
            Text("Measuring Pulse")
                .font(.title)
                .fontWeight(.bold)

            // Instructions
            Text(isMeasuring
                 ? "Please keep your finger still on the camera"
                 : "Place your finger gently over the camera and flashlight")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if measurementFailed {
                Text("Could not measure your pulse.\nPlease place your finger correctly and try again")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            
            // Countdown
            if isMeasuring {
                Text("\(remainingTime)")
                    .font(.system(size: 48, weight: .bold))
                    .padding()
            }

            
            Spacer()

            // Start button (only visible before measuring)
            if !isMeasuring {
                Button {
                    startMeasurement()
                } label: {
                    Text("Start Measurement")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)

        // Navigation to result
        .navigationDestination(isPresented: $navigateToResult) {
            if let bpm = viewModel.bpm {
                ResultView(bpm: bpm)
            }
        }
        
       

        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showInstructions = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }

        .sheet(isPresented: $showInstructions) {
            MeasurementInstructionsView()
                .presentationDetents([.medium])
        }


        
        .onDisappear {
            stopMeasurement()
            viewModel.stopCamera()
        }
    }

    
    
    // MARK: - Measurement logic

    private func startMeasurement() {
        measurementFailed = false
        isMeasuring = true
        remainingTime = 30

        viewModel.startMeasurement()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            remainingTime -= 1

            if remainingTime <= 0 {
                stopMeasurement()

                if viewModel.bpm != nil {
                    navigateToResult = true
                } else {
                    measurementFailed = true
                }
            }

        }
    }

    private func stopMeasurement() {
        timer?.invalidate()
        timer = nil
        isMeasuring = false
        viewModel.stopMeasurement()
    }
}

#Preview {
    NavigationStack {
        MeasureView()
    }
}

