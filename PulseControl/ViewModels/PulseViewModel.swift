import Foundation

final class PulseViewModel: ObservableObject {

    @Published var bpm: Int? = nil
    private let cameraService = PPGCameraService()

    init() {
        cameraService.onBPMUpdate = { [weak self] bpm in
            DispatchQueue.main.async {
                self?.bpm = bpm
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
    }
}
