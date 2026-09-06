import AppKit
import CoreLocation

/// Drives filter intensity from solar night factor when Auto is on.
@MainActor
final class AutoSunController: NSObject, CLLocationManagerDelegate {
    static let shared = AutoSunController()

    private var timer: Timer?
    private let locationManager = CLLocationManager()
    private let rampSeconds: TimeInterval = 30 * 60
    var onAppliedIntensityChange: ((Double) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func start() {
        stopTimer()
        requestLocationIfNeeded()
        tick()
        let t = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        stopTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func tick() {
        guard Preferences.isEnabled else { return }

        let cap = Preferences.intensity
        let applied: Double
        if Preferences.autoSun {
            let factor = Solar.nightFactor(
                at: Date(),
                latitude: Preferences.latitude,
                longitude: Preferences.longitude,
                rampSeconds: rampSeconds
            )
            applied = cap * factor
        } else {
            applied = cap
        }

        ColorFilterEngine.shared.setIntensity(applied)
        // Ensure engine is on when enabled
        Task { await ColorFilterEngine.shared.setEnabled(true) }
        onAppliedIntensityChange?(applied)
    }

    private func requestLocationIfNeeded() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            break // keep Berlin defaults
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        Task { @MainActor in
            Preferences.latitude = c.latitude
            Preferences.longitude = c.longitude
            self.tick()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("RedDim: location failed (\(error.localizedDescription)); using stored/default coords")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.requestLocationIfNeeded()
        }
    }
}
