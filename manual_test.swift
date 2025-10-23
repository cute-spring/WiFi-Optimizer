#!/usr/bin/env swift

import CoreWLAN
import Foundation

// Test direct CoreWLAN access
print("Testing CoreWLAN access...")

let client = CWWiFiClient.shared()
print("CWWiFiClient created successfully")

guard let interface = client.interface() else {
    print("No WiFi interface available")
    exit(1)
}

print("WiFi interface: \(interface.interfaceName ?? "unknown")")
print("Current SSID: \(interface.ssid() ?? "none")")

do {
    let networks = try interface.scanForNetworks(withSSID: nil)
    print("Found \(networks.count) networks")
    
    for (index, network) in networks.enumerated() {
        print("\nNetwork \(index + 1):")
        print("  SSID: \(network.ssid ?? "nil")")
        print("  BSSID: \(network.bssid ?? "nil")")
        print("  SSID Data: \(network.ssidData?.count ?? 0) bytes")
        
        if let ssidData = network.ssidData, !ssidData.isEmpty {
            let hexString = ssidData.map { String(format: "%02x", $0) }.joined()
            print("  SSID Data (hex): \(hexString)")
            
            if let utf8String = String(data: ssidData, encoding: .utf8) {
                print("  SSID Data (UTF-8): '\(utf8String)'")
            }
        }
    }
} catch {
    print("Scan failed: \(error)")
}