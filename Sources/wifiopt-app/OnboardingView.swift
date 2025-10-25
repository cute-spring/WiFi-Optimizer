import SwiftUI
import CoreLocation
import AppKit

struct OnboardingView: View {
    @EnvironmentObject var location: LocationPermission
    let onContinue: () -> Void

    private var locationText: String {
        switch location.authorizationStatus {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        @unknown default: return "unknown"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to Wi‑Fi Optimizer")
                .font(.title)
                .fontWeight(.semibold)

            Text("To analyze your current Wi‑Fi network, the app needs Location Services permission. macOS gates SSID/BSSID without it.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 8) {
                Text("Location: \(locationText)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            HStack(spacing: 12) {
                Button("Request Permission") {
                    Task { _ = await location.ensureAuthorization() }
                }
                .keyboardShortcut(.defaultAction)

                Button("Open Privacy Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Button("Continue") {
                    onContinue()
                }
            }
            .padding(.top, 8)

            Divider()
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("What you’ll see next:")
                    .font(.headline)
                Text("• Live scan of nearby networks and channels")
                Text("• Current network metrics (RSSI, SNR, channel)")
                Text("• Recommendations to optimize channel selection")
                Text("• Debug panel with association and permission status")
            }
            .frame(maxWidth: 640)
        }
        .padding(24)
    }
}