#!/usr/bin/env swift

import CoreLocation
import Foundation

class PermissionTest: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var semaphore = DispatchSemaphore(value: 0)
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func test() {
        print("Current authorization status: \(manager.authorizationStatus.rawValue)")
        
        switch manager.authorizationStatus {
        case .notDetermined:
            print("Requesting permission...")
            manager.requestWhenInUseAuthorization()
            semaphore.wait()
        case .denied:
            print("Permission denied")
        case .restricted:
            print("Permission restricted")
        case .authorizedWhenInUse, .authorizedAlways:
            print("Permission granted")
        @unknown default:
            print("Unknown status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Authorization changed to: \(status.rawValue)")
        semaphore.signal()
    }
}

let test = PermissionTest()
test.test()
print("Test completed")