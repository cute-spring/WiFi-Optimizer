import SwiftUI

@main
struct WiFiOptimizerApp: App {
    @StateObject private var model = ScannerModel()

    var body: some Scene {
        WindowGroup("Wi‑F Insight & Optimizer") {
            DashboardView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 540)
                .onAppear {
                    Task {
                        let status = await LocationPermission.shared.ensureAuthorization()
                        print("Final location authorization status: \(status.rawValue)")
                    }
                }
        }
    }
}