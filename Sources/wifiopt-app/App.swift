import SwiftUI
import WiFi_Optimizer

@main
struct WiFiOptimizerApp: App {
    @StateObject private var model = ScannerModel()
    @StateObject private var locationPermission = LocationPermission.shared
    @StateObject private var appState = AppState()

    var body: some Scene {
        Window("Wi‑Fi Insight & Optimizer", id: "main") {
            RootView()
                .environmentObject(model)
                .environmentObject(locationPermission)
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 540)
        }
        .commands {
            #if WIFIOPT_DEBUG
            CommandGroup(after: .sidebar) {
                Divider()
                Button("Toggle Debug Overlay") {
                    appState.isDebugPanelVisible.toggle()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            #endif
        }
    }
}