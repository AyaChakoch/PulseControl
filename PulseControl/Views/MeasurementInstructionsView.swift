//
//  MeasurementInstructionsView.swift
//  PulseControl
//
//  Created by Aya on 2025-12-24.
//

import SwiftUI

struct MeasurementInstructionsView: View {

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {

            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 8)

            Text("How to measure your pulse")
                .font(.title3)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                
                Text("• Place your finger gently over the camera and flashlight")
                Text("• Keep your finger still during the measurement")
                Text("• Sit still and breathe normally")
                Text("• The measurement takes about 30 seconds")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    MeasurementInstructionsView()
}
