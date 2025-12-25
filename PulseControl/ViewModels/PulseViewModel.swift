import Foundation

final class PulseViewModel: ObservableObject {

    @Published var bpm: Int? = nil
    @Published var category: String? = nil
    @Published var message: String? = nil
    @Published var recommendation: String? = nil
    @Published var apiError: String? = nil

    private let cameraService = PPGCameraService()
    private let apiService = ApiService()

    
    init() {
        cameraService.onBPMUpdate = { [weak self] bpm in
            DispatchQueue.main.async {
                self?.bpm = bpm
            }
        }

        cameraService.onMeasurementFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.analyzePulse(using: self?.bpm)
            }
        }
    }


    func startCamera() {
        cameraService.start()
    }
    
    
    func stopCamera() {
        cameraService.stop()
    }

    func startMeasurement() {
        cameraService.start()
        cameraService.startMeasuring()
    }
    
    func stopMeasurement() {
        cameraService.stopMeasuring()
        let finalBpm = bpm
        analyzePulse(using: finalBpm)
    }

    // API
    func analyzePulse(using bpm: Int?) {
        guard let bpm = bpm else { return }

        apiError = nil

        Task {
            do {
                let result = try await apiService.analyzePulse(bpm: bpm)

                await MainActor.run {
                    self.category = result.category
                    self.message = result.message
                    self.recommendation = result.recommendation
                }
            } catch {
                await MainActor.run {
                    self.apiError = error.localizedDescription
                }
            }
        }
    }

    
    
}
