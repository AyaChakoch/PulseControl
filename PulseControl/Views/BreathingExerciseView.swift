import SwiftUI
import AVFoundation

struct BreathingExerciseView: View {
    
    let exercise: BreathingExerciseModel
    
    @State private var totalRemainingTime: Int
    @State private var currentPhase: Phase = .inhale
    @State private var phaseRemainingTime: Int = 0
    @State private var timer: Timer?
    @State private var finished = false
    
    //for the Backgroundmusic
    @State private var backgroundPlayer: AVAudioPlayer?
    @State private var isMusicEnabled = true  // Standard: on
    
    init(exercise: BreathingExerciseModel) {
        self.exercise = exercise
        _totalRemainingTime = State(initialValue: exercise.durationSeconds)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            
            Spacer()
            
            Text(exercise.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(exercise.subtitle)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Spacer()
            
            if !finished {
                
                // Gentle guidance text
                Text("Follow the breathing rhythm below")
                    .foregroundColor(.secondary)
                
                // Current phase
                Text(currentPhase.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(phaseRemainingTime)")
                    .font(.system(size: 48, weight: .bold))
                
                Spacer()
                
                Text("Time left: \(totalRemainingTime)s")
                    .foregroundColor(.secondary)
                
            } else {
                
                // ✅ Finished state
                Text("Great job 🌿")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("You’ve completed the breathing exercise.\nTake a moment and notice how you feel.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                NavigationLink {
                    MeasureView()
                } label: {
                    PrimaryButton(title: "Measure Pulse Again")
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isMusicEnabled.toggle()
                    if isMusicEnabled {
                        startBackgroundMusic()
                    } else {
                        stopBackgroundMusic()
                    }
                } label: {
                    Image(systemName: isMusicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title3)
                }
            }
        }
        .onAppear {
            startExercise()
            if isMusicEnabled {
                startBackgroundMusic()
            }
        }
        .onDisappear {
            stopTimer()
            stopBackgroundMusic()
        }
    }
    
    // MARK: - Timer logic
    
    private func startExercise() {
        setupPhase(.inhale)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tick()
        }
    }
    
    private func tick() {
        guard totalRemainingTime > 0 else {
            finishExercise()
            return
        }
        
        totalRemainingTime -= 1
        phaseRemainingTime -= 1
        
        if phaseRemainingTime <= 0 {
            moveToNextPhase()
        }
    }
    
    private func finishExercise() {
        stopTimer()
        finished = true
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Phase handling
    
    private func setupPhase(_ phase: Phase) {
        currentPhase = phase
        
        switch phase {
        case .inhale:
            phaseRemainingTime = exercise.inhale
            
        case .hold:
            phaseRemainingTime = exercise.hold ?? 0
            
        case .exhale:
            phaseRemainingTime = exercise.exhale
            
        case .holdAfterExhale:
            phaseRemainingTime = exercise.holdAfterExhale ?? 0
        }
    }
    
    private func moveToNextPhase() {
        switch currentPhase {
        case .inhale:
            if exercise.hold != nil {
                setupPhase(.hold)
            } else {
                setupPhase(.exhale)
            }
            
        case .hold:
            setupPhase(.exhale)
            
        case .exhale:
            if exercise.holdAfterExhale != nil {
                setupPhase(.holdAfterExhale)
            } else {
                setupPhase(.inhale)
            }
            
        case .holdAfterExhale:
            setupPhase(.inhale)
        }
    }
    
    
    // Neu: Musik-Funktionen
    private func startBackgroundMusic() {
        guard isMusicEnabled else { return }
        
        // Dateiname je nach Übung wählen
        var fileName: String
        switch exercise.title {
        case "Box Breathing":
            fileName = "box_breathing_bells"      // deine MP3 für Glocken
        case "4-7-8 Breathing":
            fileName = "four_seven_eight_ocean"   // deine MP3 für Ozeanwellen
        default: // Extended Exhale
            fileName = "extended_exhale_rain"     // deine MP3 für Regen
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Musik-Datei nicht gefunden: \(fileName).mp3")
            return
        }
        
        do {
            backgroundPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundPlayer?.numberOfLoops = -1   // Endlosschleife
            backgroundPlayer?.volume = 0.4         // Leise – passe an (0.3–0.5)
            backgroundPlayer?.play()
        } catch {
            print("Fehler beim Abspielen: \(error)")
        }
    }
    
    private func stopBackgroundMusic() {
        backgroundPlayer?.stop()
        backgroundPlayer = nil
    }
    
    // MARK: - Phase enum
    
    enum Phase {
        case inhale
        case hold
        case exhale
        case holdAfterExhale
        
        var title: String {
            switch self {
            case .inhale:
                return "Inhale slowly"
            case .hold, .holdAfterExhale:
                return "Hold"
            case .exhale:
                return "Exhale slowly"
            }
        }
    }
}
    
#Preview {
    NavigationStack {
        BreathingExerciseView(
            exercise: BreathingExerciseModel(
                title: "Box Breathing",
                subtitle: "4–4–4–4 structured breathing",
                inhale: 4,
                hold: 4,
                exhale: 4,
                holdAfterExhale: 4,
                durationSeconds: 120
            )
        )
    }
}

