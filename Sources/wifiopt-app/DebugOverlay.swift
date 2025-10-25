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
        VStack(alignment: .leading, spacing: 6) {
            StatusChip("DEBUG MODE", systemImage: "ladybug", color: .yellow)
            
            Text("Location: \(locationText) • Associated: \(associatedText)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
            
            Text("SSID: \(ssidText)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
            Text("BSSID: \(bssidText)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
            Text("RSSI: \(rssiText) • Noise: \(noiseText) • SNR: \(snrText)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
            Text("Channel: \(channelText) • Band: \(bandText) • Networks: \(networksCount)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(10)
        .background(Color.black.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
        .accessibilityIdentifier("DebugOverlay")
    }
}