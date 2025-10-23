import Foundation
import CoreLocation

@MainActor
final class LocationPermission: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermission()
    private let manager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    private override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
        print("Initial location authorization status: \(authorizationStatus.rawValue)")
    }

    func ensureAuthorization() async -> CLAuthorizationStatus {
        print("Current location authorization status: \(manager.authorizationStatus.rawValue)")
        
        switch manager.authorizationStatus {
        case .notDetermined:
            print("Requesting location authorization...")
            return await withCheckedContinuation { continuation in
                self.authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        case .denied, .restricted:
            print("Location permission denied or restricted")
            return manager.authorizationStatus
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission already granted")
            return manager.authorizationStatus
        @unknown default:
            print("Unknown location authorization status")
            return manager.authorizationStatus
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            print("Location authorization changed to: \(status.rawValue)")
            authorizationStatus = status
            
            switch status {
            case .notDetermined:
                print("Location permission not determined")
            case .denied:
                print("Location permission denied")
            case .restricted:
                print("Location permission restricted")
            case .authorizedWhenInUse:
                print("Location permission granted (when in use)")
            case .authorizedAlways:
                print("Location permission granted (always)")
            @unknown default:
                print("Unknown location permission status")
            }
            
            // Resume the continuation if waiting
            if let continuation = authorizationContinuation {
                authorizationContinuation = nil
                continuation.resume(returning: status)
            }
        }
    }
}