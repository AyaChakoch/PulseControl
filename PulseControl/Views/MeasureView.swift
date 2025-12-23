//
//  MeasureView.swift
//  PulseControl
//
//  Created by Aya on 2025-12-16.
//
import SwiftUI

struct MeasureView: View {
    @StateObject private var viewModel = PulseViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.bpm.map { "BPM: \($0)" } ?? "Not measuring")

            Button("Start Measurement") { viewModel.startMeasurement() }
            Button("Stop Measurement") { viewModel.stopMeasurement() }
        }
    
        
        .onDisappear {
            viewModel.stopMeasurement()
            viewModel.stopCamera()
        }
    }
}

#Preview {
    MeasureView()
}

