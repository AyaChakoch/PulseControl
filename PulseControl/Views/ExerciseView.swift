//
//  ExerciseView.swift
//  PulseControl
//
//  Created by Aya on 2025-12-24.
//

import SwiftUI

struct ExerciseView: View {

    var body: some View {
        VStack(spacing: 24) {

            Spacer()

            Text("Quick Movement")
                .font(.title2)
                .fontWeight(.bold)


            Text("Choose one exercise below and perform it for 30–60 seconds to raise your pulse.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 28) {
                
                Text("• March in place")
                Image("march_in_place")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 110)
                
                Text("• Bodyweight squats")
                Image("squats")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 110)
                
           
                Text("• Jumping jacks")
                Image("jumping_jacks")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 110)
                
              
            }
            .padding(.horizontal)
            .fontWeight(.bold)
            .padding(.top, 24)
            
         
    

            Spacer()

            NavigationLink {
                MeasureView()
            } label: {
                PrimaryButton(title: "Measure Pulse Again")
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ExerciseView()
    }
}
