import Foundation

public struct ChannelRecommender {
    public static func recommend(networks: [NetworkInfo]) -> (twoFour: Int?, five: Int?) {
        let c24 = bestChannel(for: .twoPointFourGHz, networks: networks)
        let c5 = bestChannel(for: .fiveGHz, networks: networks)
        return (c24, c5)
    }

    public static func bestChannel(for band: WiFiBand, networks: [NetworkInfo]) -> Int? {
        let candidates = candidateChannels(for: band)
        if candidates.isEmpty { return nil }
        let bandNets = networks.filter { $0.band == band }

        var best: (ch: Int, score: Double, overlaps: Int)? = nil
        for ch in candidates {
            var score: Double = 0
            var overlaps: Int = 0
            for n in bandNets {
                let wUnits = bandwidthUnits(n.bandwidthMHz, band: band)
                let dist = abs(n.channel - ch)
                let half = max(1, wUnits / 2)
                if dist <= half { // overlapping influence
                    overlaps += 1
                    let base = normRSSI(n.rssi)
                    let falloff = 1.0 - (Double(dist) / Double(half)) // triangular
                    score += base * max(0.0, falloff)
                }
            }
            if best == nil || score < best!.score || (score == best!.score && overlaps < best!.overlaps) {
                best = (ch, score, overlaps)
            }
        }

        // Prefer 1/6/11 for 2.4GHz when tied or near-tied
        if band == .twoPointFourGHz, let b = best {
            let preferred = [1, 6, 11]
            if preferred.contains(b.ch) { return b.ch }
            // Find best among preferred if scores within 10%
            let scores = preferred.map { ch -> (Int, Double, Int) in
                var s: Double = 0; var o: Int = 0
                for n in bandNets {
                    let wUnits = bandwidthUnits(n.bandwidthMHz, band: band)
                    let dist = abs(n.channel - ch)
                    let half = max(1, wUnits / 2)
                    if dist <= half { o += 1; s += normRSSI(n.rssi) * (1.0 - (Double(dist)/Double(half))) }
                }
                return (ch, s, o)
            }
            if let bestPref = scores.min(by: { $0.1 == $1.1 ? $0.2 < $1.2 : $0.1 < $1.1 }) { return bestPref.0 }
        }

        return best?.ch
    }

    static func candidateChannels(for band: WiFiBand) -> [Int] {
        switch band {
        case .twoPointFourGHz:
            return Array(1...11)
        case .fiveGHz:
            // Non-DFS common 20MHz primaries
            return [36,40,44,48,149,153,157,161]
        case .sixGHz:
            return []
        }
    }

    static func bandwidthUnits(_ mhz: Int, band: WiFiBand) -> Int {
        let base = max(1, mhz / 20)
        let multiplier: Int
        switch band {
        case .twoPointFourGHz: multiplier = 4
        case .fiveGHz: multiplier = 4
        case .sixGHz: multiplier = 8
        }
        return base * multiplier
    }

    static func normRSSI(_ rssi: Int) -> Double {
        let minR = -100
        let maxR = -30
        let c = max(min(rssi, maxR), minR)
        return Double(c - minR) / Double(maxR - minR)
    }
}