import Foundation
import CoreWLAN
 
// Lightweight debug logging
// Debug.log prints only when WIFIOPT_DEBUG env var is set.

public enum WiFiBand: String, CaseIterable {
    case twoPointFourGHz = "2.4 GHz"
    case fiveGHz = "5 GHz"
    case sixGHz = "6 GHz"

    public static func from(channel: CWChannel) -> WiFiBand {
        switch channel.channelBand {
            case .band2GHz: return .twoPointFourGHz
            case .band5GHz: return .fiveGHz
            case .band6GHz: return .sixGHz
            case .bandUnknown: return .twoPointFourGHz
            @unknown default: return .twoPointFourGHz
        }
    }
}

public struct NetworkInfo: Identifiable, Equatable {
    public let id: String // BSSID
    public var ssid: String?
    public let bssid: String
    public let rssi: Int
    public let noise: Int
    public let snr: Int
    public let channel: Int
    public let band: WiFiBand
    public let bandwidthMHz: Int
    public let security: String
    
    // Convenience initializer for system profiler data
    public init(id: String, ssid: String?, bssid: String, rssi: Int, noise: Int, snr: Int, channel: Int, band: WiFiBand, bandwidthMHz: Int, security: String) {
        self.id = id
        self.ssid = ssid
        self.bssid = bssid
        self.rssi = rssi
        self.noise = noise
        self.snr = snr
        self.channel = channel
        self.band = band
        self.bandwidthMHz = bandwidthMHz
        self.security = security
    }

    public init(network: CWNetwork) {
        self.id = network.bssid ?? UUID().uuidString
        self.ssid = Self.decodeSSID(from: network)
        self.bssid = network.bssid ?? "Unknown"
        self.rssi = network.rssiValue
        self.noise = network.noiseMeasurement
        self.snr = self.rssi - self.noise
        self.channel = network.wlanChannel?.channelNumber ?? 0
        self.band = network.wlanChannel.map { WiFiBand.from(channel: $0) } ?? .twoPointFourGHz
        self.bandwidthMHz = network.wlanChannel.map { Self.widthMHz($0) } ?? 20
        self.security = Self.securityFrom(network)
        
        // Debug output to see what we're getting
        print("Network created - SSID: '\(self.ssid ?? "nil")', BSSID: \(self.bssid)")
        if let ssidData = network.ssidData {
            print("  SSID data available: \(ssidData.count) bytes")
        } else {
            print("  No SSID data available")
        }
    }

    static func widthMHz(_ channel: CWChannel) -> Int {
        switch channel.channelWidth {
            case .width20MHz: return 20
            case .width40MHz: return 40
            case .width80MHz: return 80
            case .width160MHz: return 160
            case .widthUnknown: return 20
            @unknown default: return 20
        }
    }

    static func decodeSSID(from network: CWNetwork) -> String {
        // First, try to get the SSID directly from the network object
        if let ssid = network.ssid, !ssid.isEmpty {
            print("Direct SSID access successful: \(ssid)")
            return ssid
        }
        
        // If direct access fails, try to decode from ssidData
        guard let ssidData = network.ssidData else {
            print("No SSID data available for network")
            return "<no-ssid-data>"
        }
        
        print("SSID data length: \(ssidData.count) bytes")
        
        // Try multiple encoding strategies
        let encodings: [String.Encoding] = [.utf8, .ascii, .isoLatin1, .utf16, .utf32]
        
        for encoding in encodings {
            if let decoded = String(data: ssidData, encoding: encoding), !decoded.isEmpty {
                let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    print("Successfully decoded SSID with \(encoding): \(trimmed)")
                    return trimmed
                }
            }
        }
        
        // Try to extract printable ASCII characters
        let bytes = [UInt8](ssidData)
        let printableChars = bytes.compactMap { byte in
            (32...126).contains(byte) ? Character(UnicodeScalar(byte)) : nil
        }
        
        if !printableChars.isEmpty {
            let result = String(printableChars)
            print("Extracted printable ASCII: \(result)")
            return result
        }
        
        // Try to use the BSSID as a fallback identifier
        if let bssid = network.bssid, !bssid.isEmpty {
            print("Using BSSID as fallback: \(bssid)")
            return "Network-\(bssid.suffix(8))"
        }
        
        // Last resort: hex representation
        let hexString = ssidData.map { String(format: "%02x", $0) }.joined()
        print("Hex representation: \(hexString)")
        return "hex-\(hexString.prefix(12))"
    }

    static func securityFrom(_ network: CWNetwork) -> String {
        // Check supported security modes, prefer strongest labels
        // Enterprise (WPA3/WPA2/WPA)
        if network.supportsSecurity(.enterprise) { return "WPA3 Enterprise" }
        if network.supportsSecurity(.wpa2Enterprise) { return "WPA2 Enterprise" }
        if network.supportsSecurity(.wpaEnterprise) { return "WPA Enterprise" }
        // Personal (WPA3/WPA2/WPA)
        if network.supportsSecurity(.personal) { return "WPA3 Personal" }
        if network.supportsSecurity(.wpa2Personal) { return "WPA2" }
        if network.supportsSecurity(.wpaPersonalMixed) { return "WPA/WPA2" }
        if network.supportsSecurity(.wpaPersonal) { return "WPA" }
        // Legacy/Open
        if network.supportsSecurity(.dynamicWEP) { return "WEP" }
        if network.supportsSecurity(.none) { return "Open" }
        return "Unknown"
    }

    static func securityLabel(_ sec: CWSecurity) -> String {
        switch sec {
        case .none: return "Open"
        case .dynamicWEP: return "WEP"
        case .WEP: return "WEP"
        case .wpaPersonal: return "WPA Personal"
        case .wpaPersonalMixed: return "WPA/WPA2 Personal"
        case .wpa2Personal: return "WPA2 Personal"
        case .personal: return "WPA3 Personal"
        case .wpaEnterprise: return "WPA Enterprise"
        case .wpaEnterpriseMixed: return "WPA Enterprise Mixed"
        case .wpa2Enterprise: return "WPA2 Enterprise"
        case .enterprise: return "WPA3 Enterprise"
        case .wpa3Personal: return "WPA3 Personal"
        case .wpa3Enterprise: return "WPA3 Enterprise"
        case .wpa3Transition: return "WPA2/WPA3 Personal"
        case .OWE: return "OWE"
        case .oweTransition: return "OWE Transition"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}

public struct InterfaceInfo {
    public let ssid: String?
    public let bssid: String?
    public let rssi: Int
    public let noise: Int
    public let snr: Int
    public let channel: Int?
    public let band: WiFiBand?
}

public final class WiFiScanner {
    private let client = CWWiFiClient.shared()
    
    public init() {}

    public func scan(bandFilter: WiFiBand? = nil) throws -> ([NetworkInfo], InterfaceInfo) {
        Debug.log("scan() start, bandFilter=\(String(describing: bandFilter?.rawValue))")
        // Prefer CoreWLAN first
        guard let iface = CWWiFiClient.shared().interface() else {
            throw NSError(domain: "WiFiScanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "No Wi‑Fi interface found"])
        }
    
        var nets: Set<CWNetwork>
        do {
            // Comprehensive scan including hidden networks
            nets = try iface.scanForNetworks(withSSID: nil, includeHidden: true)
        } catch {
            // Fallback basic scan
            nets = try iface.scanForNetworks(withSSID: nil, includeHidden: false)
        }
        // If poor results, try again without hidden networks
        if nets.isEmpty || nets.allSatisfy({ $0.ssid?.isEmpty != false }) {
            do {
                nets = try iface.scanForNetworks(withSSID: nil, includeHidden: false)
            } catch {
                // Keep original results
            }
        }
    
        let mapped: [NetworkInfo] = nets.compactMap { net in
            let info = NetworkInfo(network: net)
            if let f = bandFilter { return info.band == f ? info : nil }
            return info
        }
    
        let rssi = iface.rssiValue()
        let noise = iface.noiseMeasurement()
        let snr = rssi - noise
        let channel = iface.wlanChannel()?.channelNumber
        let band = iface.wlanChannel().map { WiFiBand.from(channel: $0) }
        let current = InterfaceInfo(
            ssid: iface.ssid(),
            bssid: iface.bssid(),
            rssi: rssi,
            noise: noise,
            snr: snr,
            channel: channel,
            band: band
        )
    
        if !mapped.isEmpty {
            let ss = iface.ssid() ?? "nil"
            let bs = iface.bssid() ?? "nil"
            Debug.log("CoreWLAN scan returned \(mapped.count) networks; current ssid=\(ss), bssid=\(bs)")
            return (mapped, current)
        }
    
        // Fallback to system_profiler if CoreWLAN yields no networks or is heavily gated
        let systemNetworks = SystemProfilerWiFi.getNetworks()
        if !systemNetworks.isEmpty {
            print("Using system profiler fallback - found \(systemNetworks.count) networks")
            Debug.log("system_profiler returned \(systemNetworks.count) networks (fallback)")
            var filtered = systemNetworks.filter { net in
                if let f = bandFilter { return net.band == f }
                return true
            }
    
            // Enrich or synthesize current network entry if possible
            if let currentSSID = iface.ssid(), let currentBSSID = iface.bssid() {
                func norm(_ s: String) -> String { s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\""))).lowercased() }
                let target = norm(currentSSID)
                if let idx = filtered.firstIndex(where: { ($0.ssid.map(norm) ?? "") == target }) {
                    let n = filtered[idx]
                    filtered[idx] = NetworkInfo(
                        id: n.id,
                        ssid: currentSSID,
                        bssid: currentBSSID,
                        rssi: n.rssi,
                        noise: n.noise,
                        snr: n.snr,
                        channel: n.channel,
                        band: n.band,
                        bandwidthMHz: n.bandwidthMHz,
                        security: n.security
                    )
                    Debug.log("enriched system_profiler entry for SSID='\(currentSSID)' with BSSID='\(currentBSSID)'")
                } else {
                    let bandwidth = iface.wlanChannel().map { NetworkInfo.widthMHz($0) } ?? 20
                    let synthesized = NetworkInfo(
                        id: currentBSSID,
                        ssid: currentSSID,
                        bssid: currentBSSID,
                        rssi: rssi,
                        noise: noise,
                        snr: snr,
                        channel: channel ?? 0,
                        band: band ?? .twoPointFourGHz,
                        bandwidthMHz: bandwidth,
                        security: "Unknown"
                    )
                    filtered.append(synthesized)
                    Debug.log("synthesized current network entry (SSID='\(currentSSID)', BSSID='\(currentBSSID)')")
                }
            }
    
            Debug.log("returning \(filtered.count) networks via system_profiler fallback with CoreWLAN-based InterfaceInfo")
            return (filtered, current)
        }
    
        Debug.log("No networks found by CoreWLAN or system_profiler; returning empty list with current interface info")
        return ([], current)
    }
}
