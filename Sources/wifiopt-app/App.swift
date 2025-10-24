import SwiftUI

@main
struct WiFiOptimizerApp: App {
    @StateObject private var model = ScannerModel()
    @StateObject private var locationPermission = LocationPermission.shared

    var body: some Scene {
        WindowGroup("Wi‑F Insight & Optimizer") {
            RootView()
                .environmentObject(model)
                .environmentObject(locationPermission)
                .frame(minWidth: 900, minHeight: 540)
        }
    }
}