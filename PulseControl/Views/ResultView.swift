//
//  ResultView.swift
//  PulseControl
//
//  Created by Aya on 2025-12-16.
//

import SwiftUI

struct ResultView: View {
    let bpm: Int
    
    // Hinzugefügt: Zugriff auf das ViewModel, um Server-Daten zu nutzen
    @ObservedObject var viewModel: PulseViewModel
    
    // Berechnete Kategorie: zuerst Server, dann lokal als Fallback
    private var effectiveCategory: PulseCategory {
        if let serverCategoryString = viewModel.category,
           let serverCategory = PulseCategory.from(serverString: serverCategoryString) {
            return serverCategory
        }
        // Fallback: lokale Berechnung
        return PulseCategory.from(bpm: bpm)
    }
    
    // Nachricht: zuerst vom Server, sonst lokal
    private var effectiveMessage: String {
        if let serverMessage = viewModel.message, !serverMessage.isEmpty {
            return serverMessage
        }
        return effectiveCategory.message
    }
    
    // Empfehlung wird aktuell nicht angezeigt, könnte aber später hinzugefügt werden
    // private var effectiveRecommendation: String { ... }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            Text("Your measurement is")
                .font(.title)
                .fontWeight(.bold)
            
            Text("BPM: \(bpm)")
                .font(.system(size: 40, weight: .bold))
            
            // Kategorie-Titel mit passender Farbe und Schriftgröße
            Text(effectiveCategory.title)
                .font(effectiveCategory.fontSize)
                .fontWeight(effectiveCategory.fontWeight)
                .foregroundColor(effectiveCategory.color)
            
            // Nachricht – jetzt dynamisch vom Server oder lokal
            Text(effectiveMessage)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Spacer()
            
            // Buttons je nach Kategorie
            VStack(spacing: 14) {
                
                // Immer: Nochmal messen
                NavigationLink {
                    MeasureView()
                } label: {
                    PrimaryButton(title: "Measure Again")
                }
                
                // Sekundäre Aktion je nach Kategorie
                switch effectiveCategory {
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

// MARK: - Erweiterung des PulseCategory-Enums für Server-Kategorie

extension PulseCategory {
    // Neu: Konvertiert Server-String ("low", "normal", "high") in Enum
    static func from(serverString: String) -> PulseCategory? {
        switch serverString.lowercased() {
        case "low": return .low
        case "normal": return .normal
        case "high": return .high
        default: return nil
        }
    }
}

// MARK: - Pulse Category (unverändert)

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
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .low, .high: return .red
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .normal: return .semibold
        case .low, .high: return .bold
        }
    }
    
    var fontSize: Font {
        switch self {
        case .low: return .title2
        case .normal, .high: return .headline
        }
    }
}

// MARK: - Reusable buttons (unverändert)

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
        // Für Preview: ein Dummy-ViewModel erstellen
        ResultView(bpm: 85, viewModel: PulseViewModel())
    }
}
