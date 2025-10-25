import Foundation
import WiFi_Optimizer

@MainActor
final class ScannerModel: ObservableObject {
    @Published var networks: [NetworkInfo] = []
    @Published var current: InterfaceInfo? = nil
    @Published var bandFilter: WiFiBand? = nil
    @Published var isScanning: Bool = false
    @Published var recommended24: Int? = nil
    @Published var recommended5: Int? = nil
    @Published var networkAnalysis: NetworkAnalysis? = nil
    @Published var scanInterval: Double = 3.0 {
        didSet {
            if isScanning { restartTimer() }
        }
    }

    private let scanner = WiFiScanner()
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        isScanning = true
        restartTimer()
        tick()
    }

    func stop() {
        isScanning = false
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func tick() {
        do {
            let (nets, iface) = try scanner.scan(bandFilter: bandFilter)
            var enriched = nets
            if let currentBSSID = iface.bssid, let currentSSID = iface.ssid, !currentSSID.isEmpty {
                for i in 0..<enriched.count {
                    if enriched[i].bssid == currentBSSID {
                        enriched[i].ssid = currentSSID
                    }
                }
            }
            Debug.log("tick: nets=\(enriched.count), iface ssid='\(iface.ssid ?? "nil")', bssid='\(iface.bssid ?? "nil")', rssi=\(iface.rssi), ch=\(String(describing: iface.channel))")
            self.networks = enriched.sorted { $0.rssi > $1.rssi }
            self.current = iface
            let recs = ChannelRecommender.recommend(networks: nets)
            self.recommended24 = recs.twoFour
            self.recommended5 = recs.five
            
            // Generate network analysis for current network
            let currentNetwork = findCurrentNetwork(from: enriched, interface: iface)
            if let c = currentNetwork {
                Debug.log("current match: ssid='\(c.ssid ?? "nil")', bssid='\(c.bssid)', ch=\(c.channel), rssi=\(c.rssi)")
            } else {
                Debug.log("current match: NOT FOUND")
            }
            self.networkAnalysis = NetworkAnalysis(currentNetwork: currentNetwork, allNetworks: enriched)
        } catch {
            // Keep scanning; optionally expose error state
            Debug.log("tick error: \(error.localizedDescription)")
        }
    }
    
    private func findCurrentNetwork(from networks: [NetworkInfo], interface: InterfaceInfo) -> NetworkInfo? {
        // Prefer matching by BSSID; fallback to normalized SSID and finally by proximity
        if let currentBSSID = interface.bssid {
            if let byBSSID = networks.first(where: { $0.bssid == currentBSSID }) { return byBSSID }
        }
        if let currentSSID = interface.ssid, !currentSSID.isEmpty {
            func norm(_ s: String) -> String { s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\""))).lowercased() }
            let target = norm(currentSSID)
            if let bySSID = networks.first(where: { ($0.ssid.map(norm) ?? "") == target }) { return bySSID }
        }
        // As a last resort, match by nearest RSSI/channel to the interface
        if let ch = interface.channel {
            let candidates = networks.filter { $0.channel == ch }
            if let rssi = Optional(interface.rssi), let best = candidates.min(by: { abs($0.rssi - rssi) < abs($1.rssi - rssi) }) {
                return best
            }
        }
        return nil
    }
}