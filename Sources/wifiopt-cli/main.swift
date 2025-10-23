import Foundation
import WiFi_Optimizer

func bandArg(_ arg: String?) -> WiFiBand? {
    guard let a = arg?.lowercased() else { return nil }
    switch a {
    case "2.4", "2.4ghz", "2_4", "2": return .twoPointFourGHz
    case "5", "5ghz": return .fiveGHz
    case "6", "6ghz": return .sixGHz
    default: return nil
    }
}

let scanner = WiFiScanner()
let filter = bandArg(CommandLine.arguments.dropFirst().first)

func printHeader(filter: WiFiBand?) {
    var header = "Time\tSSID\tBSSID\tRSSI\tNoise\tSNR\tChannel\tBand\tWidth\tSecurity"
    if let f = filter { header += "\t(Filter: \(f.rawValue))" }
    print(header)
}

printHeader(filter: filter)

while true {
    do {
        let (nets, current) = try scanner.scan(bandFilter: filter)
        let ts = ISO8601DateFormatter().string(from: Date())
        for n in nets.sorted(by: { $0.rssi > $1.rssi }) {
            let isCurrent = (n.bssid == (current.bssid ?? ""))
            let star = isCurrent ? "*" : " "
            print("\(ts)\t\(n.ssid ?? "<hidden>")\t\(n.bssid)\t\(n.rssi)\t\(n.noise)\t\(n.snr)\t\(n.channel)\t\(n.band.rawValue)\t\(n.bandwidthMHz)\t\(n.security)\(star)")
        }
        Thread.sleep(forTimeInterval: 3.0)
    } catch {
        fputs("Error: \(error)\n", stderr)
        Thread.sleep(forTimeInterval: 3.0)
    }
}