import SwiftUI

@main
struct WiFiOptimizerApp: App {
    @StateObject private var model = ScannerModel()
    @StateObject private var locationPermission = LocationPermission.shared
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("Wi‑Fi Insight & Optimizer") {
            RootView()
                .environmentObject(model)
                .environmentObject(locationPermission)
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 540)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Toggle Debug Panel") {
                    appState.isDebugPanelVisible.toggle()
                }
                .keyboardShortcut("d", modifiers: .command)
            }
        }
    }
}