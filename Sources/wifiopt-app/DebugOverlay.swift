import SwiftUI
import CoreLocation
import WiFi_Optimizer

struct DebugOverlay: View {
    let interface: InterfaceInfo?
    let networksCount: Int
    let locationStatus: CLAuthorizationStatus

    private var ssidText: String { interface?.ssid ?? "<nil>" }
    private var bssidText: String { interface?.bssid ?? "<nil>" }
    private var rssiText: String {
        if let rssi = interface?.rssi { return "\(rssi) dBm" }
        return "<nil>"
    }
    private var noiseText: String {
        if let noise = interface?.noise { return "\(noise) dBm" }
        return "<nil>"
    }
    private var snrText: String {
        if let snr = interface?.snr { return "\(snr) dB" }
        return "<nil>"
    }
    private var channelText: String {
        if let ch = interface?.channel { return "\(ch)" }
        return "<nil>"
    }
    private var bandText: String { interface?.band?.rawValue ?? "<nil>" }
    private var associatedText: String { interface?.ssid == nil ? "No" : "Yes" }
    private var locationText: String {
        switch locationStatus {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        @unknown default: return "unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DEBUG MODE")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.yellow)

            Text("Location: \(locationText) | Associated: \(associatedText)")
                .font(.caption2)
                .foregroundColor(.white)

            Text("SSID: \(ssidText)")
                .font(.caption2)
                .foregroundColor(.white)
            Text("BSSID: \(bssidText)")
                .font(.caption2)
                .foregroundColor(.white)
            Text("RSSI: \(rssiText) | Noise: \(noiseText) | SNR: \(snrText)")
                .font(.caption2)
                .foregroundColor(.white)
            Text("Channel: \(channelText) | Band: \(bandText) | Networks: \(networksCount)")
                .font(.caption2)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .shadow(radius: 4)
        .accessibilityIdentifier("DebugOverlay")
    }
}