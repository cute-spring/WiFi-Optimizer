import Foundation

public struct SystemProfilerWiFi {
    public static func getNetworks() -> [NetworkInfo] {
        Debug.log("system_profiler SPAirPortDataType start")
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPAirPortDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let parsed = parseSystemProfilerOutput(output)
            Debug.log("system_profiler parsed networks=\(parsed.count)")
            return parsed
        } catch {
            print("Failed to run system_profiler: \(error)")
            Debug.log("system_profiler failed: \(error.localizedDescription)")
            return []
        }
    }
    
    private static func parseSystemProfilerOutput(_ output: String) -> [NetworkInfo] {
        var networks: [NetworkInfo] = []
        let lines = output.components(separatedBy: .newlines)
        
        var currentNetwork: [String: String] = [:]
        var inOtherNetworks = false
        var inCurrentNetwork = false
        var networkName: String?
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check for current network section
            if trimmed == "Current Network Information:" {
                inCurrentNetwork = true
                inOtherNetworks = false
                Debug.log("parse: entering Current Network Information at line \(index)")
                continue
            }
            
            // Check for other networks section
            if trimmed == "Other Local Wi-Fi Networks:" {
                inOtherNetworks = true
                inCurrentNetwork = false
                Debug.log("parse: entering Other Local Wi-Fi Networks at line \(index)")
                continue
            }
            
            // Reset flags when we hit a new interface (8 spaces, not 12)
            if line.hasPrefix("        ") && !line.hasPrefix("            ") && line.hasSuffix(":") && !line.contains("Network Information") && !line.contains("Other Local Wi-Fi Networks") {
                inOtherNetworks = false
                inCurrentNetwork = false
                continue
            }
            
            // Parse current network (connected network)
            if inCurrentNetwork {
                if line.hasPrefix("            ") && line.hasSuffix(":") && !line.contains("Network Information") {
                    // Save previous network if we have one
                    if let name = networkName, !currentNetwork.isEmpty {
                        if let network = createNetworkInfo(name: name, properties: currentNetwork) {
                            networks.append(network)
                            Debug.log("parse current: appended network name='\(name)' rssi=\(network.rssi) ch=\(network.channel)")
                        }
                    }
                    
                    // Start new network
                    networkName = String(trimmed.dropLast()) // Remove colon
                    currentNetwork = [:]
                } else if line.hasPrefix("              ") && line.contains(": ") {
                    // This is a property of the current network
                    let parts = trimmed.components(separatedBy: ": ")
                    if parts.count >= 2 {
                        let key = parts[0]
                        let value = parts.dropFirst().joined(separator: ": ")
                        currentNetwork[key] = value
                    }
                }
            }
            
            // Parse other networks
            if inOtherNetworks {
                if line.hasPrefix("            ") && line.hasSuffix(":") && !line.hasPrefix("              ") {
                    // Save previous network if we have one
                    if let name = networkName, !currentNetwork.isEmpty {
                        if let network = createNetworkInfo(name: name, properties: currentNetwork) {
                            networks.append(network)
                            Debug.log("parse other: appended network name='\(name)' rssi=\(network.rssi) ch=\(network.channel)")
                        }
                    }
                    
                    // Start new network
                    networkName = String(trimmed.dropLast()) // Remove colon
                    currentNetwork = [:]
                } else if line.hasPrefix("              ") && line.contains(": ") {
                    // This is a property of the current network
                    let parts = trimmed.components(separatedBy: ": ")
                    if parts.count >= 2 {
                        let key = parts[0]
                        let value = parts.dropFirst().joined(separator: ": ")
                        currentNetwork[key] = value
                    }
                }
            }
        }
        
        // Don't forget the last network
        if let name = networkName, !currentNetwork.isEmpty {
            if let network = createNetworkInfo(name: name, properties: currentNetwork) {
                networks.append(network)
                Debug.log("parse end: appended final network name='\(name)' rssi=\(network.rssi) ch=\(network.channel)")
            }
        }
        
        return networks
    }
    
    private static func createNetworkInfo(name: String, properties: [String: String]) -> NetworkInfo? {
        // Parse signal and noise from "Signal / Noise" property
        var signal: Int = -100
        var noise: Int = -100
        
        if let signalNoise = properties["Signal / Noise"] {
            let parts = signalNoise.components(separatedBy: " / ")
            if parts.count >= 2 {
                if let signalValue = Int(parts[0].replacingOccurrences(of: " dBm", with: "")) {
                    signal = signalValue
                }
                if let noiseValue = Int(parts[1].replacingOccurrences(of: " dBm", with: "")) {
                    noise = noiseValue
                }
            }
        }
        
        // Parse channel from "Channel" property
        var channel: Int = 0
        var band: WiFiBand = .twoPointFourGHz
        var bandwidth: Int = 20
        
        if let channelInfo = properties["Channel"] {
            // Format: "6 (2GHz, 20MHz)" or "36 (5GHz, 160MHz)"
            let parts = channelInfo.components(separatedBy: " (")
            if let channelNum = Int(parts[0]) {
                channel = channelNum
            }
            
            if parts.count > 1 {
                let bandwidthInfo = parts[1].replacingOccurrences(of: ")", with: "")
                let bandParts = bandwidthInfo.components(separatedBy: ", ")
                if bandParts.count >= 2 {
                    let bandStr = bandParts[0]
                    let bandwidthStr = bandParts[1]
                    
                    // Parse band
                    if bandStr.contains("2GHz") {
                        band = .twoPointFourGHz
                    } else if bandStr.contains("5GHz") {
                        band = .fiveGHz
                    } else if bandStr.contains("6GHz") {
                        band = .sixGHz
                    }
                    
                    // Parse bandwidth
                    if let bw = Int(bandwidthStr.replacingOccurrences(of: "MHz", with: "")) {
                        bandwidth = bw
                    }
                }
            }
        }
        
        // Get security
        let security = properties["Security"] ?? "Unknown"
        
        return NetworkInfo(
            id: name,
            ssid: name,
            bssid: name, // Using name as BSSID since system profiler doesn't provide actual BSSID
            rssi: signal,
            noise: noise,
            snr: signal - noise,
            channel: channel,
            band: band,
            bandwidthMHz: bandwidth,
            security: security
        )
    }
}