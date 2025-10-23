import Foundation

public struct NetworkAnalysis {
    public let currentNetwork: NetworkInfo?
    public let performanceScore: Double
    public let signalQuality: SignalQuality
    public let interferenceFactors: [InterferenceFactor]
    public let recommendations: [Recommendation]
    public let detailedMetrics: DetailedMetrics
    
    public init(currentNetwork: NetworkInfo?, allNetworks: [NetworkInfo]) {
        self.currentNetwork = currentNetwork
        self.performanceScore = NetworkAnalyzer.calculatePerformanceScore(for: currentNetwork, in: allNetworks)
        self.signalQuality = NetworkAnalyzer.evaluateSignalQuality(for: currentNetwork)
        self.interferenceFactors = NetworkAnalyzer.analyzeInterference(for: currentNetwork, in: allNetworks)
        self.recommendations = NetworkAnalyzer.generateRecommendations(for: currentNetwork, in: allNetworks)
        self.detailedMetrics = NetworkAnalyzer.calculateDetailedMetrics(for: currentNetwork, in: allNetworks)
    }
}

public struct DetailedMetrics {
    public let channelUtilization: Double
    public let neighboringNetworks: Int
    public let sameChannelNetworks: Int
    public let overlappingChannels: Int
    public let averageNeighborRSSI: Double
    public let channelCongestionLevel: CongestionLevel
    
    public enum CongestionLevel: String, CaseIterable {
        case low = "低"
        case moderate = "中等"
        case high = "高"
        case severe = "严重"
    }
}

public enum SignalQuality: String, CaseIterable {
    case excellent = "优秀"
    case good = "良好"
    case fair = "一般"
    case poor = "较差"
    case veryPoor = "很差"
    
    public var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        case .veryPoor: return "red"
        }
    }
    
    public var description: String {
        switch self {
        case .excellent: return "信号强度极佳，连接稳定"
        case .good: return "信号强度良好，性能稳定"
        case .fair: return "信号强度一般，可能偶有波动"
        case .poor: return "信号强度较差，可能影响性能"
        case .veryPoor: return "信号强度很差，建议更换位置"
        }
    }
}

public struct InterferenceFactor {
    public let type: InterferenceType
    public let severity: Severity
    public let description: String
    public let impact: String
    
    public enum InterferenceType: String, CaseIterable {
        case channelOverlap = "信道重叠"
        case highDensity = "网络密度过高"
        case weakSignal = "信号强度不足"
        case noisyEnvironment = "环境噪声过大"
        case bandwidthLimitation = "带宽限制"
        case frequencyBandCongestion = "频段拥塞"
    }
    
    public enum Severity: String, CaseIterable {
        case low = "轻微"
        case moderate = "中等"
        case high = "严重"
        case critical = "极严重"
    }
}

public struct Recommendation {
    public let type: RecommendationType
    public let priority: Priority
    public let title: String
    public let description: String
    public let expectedImprovement: String
    
    public enum RecommendationType: String, CaseIterable {
        case channelChange = "更换信道"
        case bandChange = "更换频段"
        case positionOptimization = "位置优化"
        case routerUpgrade = "设备升级"
        case environmentalChange = "环境改善"
        case configurationChange = "配置优化"
    }
    
    public enum Priority: String, CaseIterable {
        case high = "高"
        case medium = "中"
        case low = "低"
    }
}

public class NetworkAnalyzer {
    
    public static func calculatePerformanceScore(for network: NetworkInfo?, in allNetworks: [NetworkInfo]) -> Double {
        guard let network = network else { return 0.0 }
        
        var score = 0.0
        
        // Signal strength score (40% weight)
        let signalScore = calculateSignalScore(rssi: network.rssi)
        score += signalScore * 0.4
        
        // SNR score (30% weight)
        let snrScore = calculateSNRScore(snr: network.snr)
        score += snrScore * 0.3
        
        // Channel congestion score (20% weight)
        let congestionScore = calculateCongestionScore(for: network, in: allNetworks)
        score += congestionScore * 0.2
        
        // Bandwidth score (10% weight)
        let bandwidthScore = calculateBandwidthScore(bandwidth: network.bandwidthMHz)
        score += bandwidthScore * 0.1
        
        return min(100.0, max(0.0, score))
    }
    
    public static func evaluateSignalQuality(for network: NetworkInfo?) -> SignalQuality {
        guard let network = network else { return .veryPoor }
        
        switch network.rssi {
        case -30...0: return .excellent
        case -50...(-31): return .good
        case -70...(-51): return .fair
        case -80...(-71): return .poor
        default: return .veryPoor
        }
    }
    
    public static func analyzeInterference(for network: NetworkInfo?, in allNetworks: [NetworkInfo]) -> [InterferenceFactor] {
        guard let network = network else { return [] }
        
        var factors: [InterferenceFactor] = []
        
        // Check signal strength
        if network.rssi < -70 {
            factors.append(InterferenceFactor(
                type: .weakSignal,
                severity: network.rssi < -80 ? .critical : .high,
                description: "当前信号强度为 \(network.rssi) dBm，低于理想范围",
                impact: "可能导致连接不稳定、速度下降"
            ))
        }
        
        // Check noise level
        if network.noise > -85 {
            factors.append(InterferenceFactor(
                type: .noisyEnvironment,
                severity: network.noise > -80 ? .high : .moderate,
                description: "环境噪声水平为 \(network.noise) dBm，较高",
                impact: "降低信号质量，影响数据传输效率"
            ))
        }
        
        // Check channel overlap
        let sameChannelNetworks = allNetworks.filter { $0.channel == network.channel && $0.id != network.id }
        if sameChannelNetworks.count > 2 {
            factors.append(InterferenceFactor(
                type: .channelOverlap,
                severity: sameChannelNetworks.count > 5 ? .high : .moderate,
                description: "信道 \(network.channel) 上有 \(sameChannelNetworks.count) 个其他网络",
                impact: "信道拥塞可能导致速度下降和延迟增加"
            ))
        }
        
        // Check network density
        let nearbyNetworks = allNetworks.filter { $0.rssi > -80 && $0.id != network.id }
        if nearbyNetworks.count > 10 {
            factors.append(InterferenceFactor(
                type: .highDensity,
                severity: nearbyNetworks.count > 20 ? .high : .moderate,
                description: "附近检测到 \(nearbyNetworks.count) 个强信号网络",
                impact: "高密度网络环境可能造成频谱竞争"
            ))
        }
        
        return factors
    }
    
    public static func generateRecommendations(for network: NetworkInfo?, in allNetworks: [NetworkInfo]) -> [Recommendation] {
        guard let network = network else { return [] }
        
        var recommendations: [Recommendation] = []
        
        // Signal strength recommendations
        if network.rssi < -70 {
            recommendations.append(Recommendation(
                type: .positionOptimization,
                priority: .high,
                title: "优化设备位置",
                description: "尝试移动到更靠近路由器的位置，或调整路由器天线角度",
                expectedImprovement: "信号强度可提升 5-15 dBm"
            ))
        }
        
        // Channel recommendations
        let channelAnalysis = analyzeChannelOptions(for: network, in: allNetworks)
        if let betterChannel = channelAnalysis.betterChannel {
            recommendations.append(Recommendation(
                type: .channelChange,
                priority: .medium,
                title: "更换到信道 \(betterChannel)",
                description: "当前信道 \(network.channel) 拥塞较严重，建议切换到信道 \(betterChannel)",
                expectedImprovement: "减少干扰，提升 20-40% 性能"
            ))
        }
        
        // Band recommendations
        if network.band == .twoPointFourGHz {
            let fiveGHzNetworks = allNetworks.filter { $0.band == .fiveGHz }
            if fiveGHzNetworks.count < 5 {
                recommendations.append(Recommendation(
                    type: .bandChange,
                    priority: .medium,
                    title: "切换到 5GHz 频段",
                    description: "5GHz 频段相对不拥塞，可提供更好的性能",
                    expectedImprovement: "速度提升 50-100%，延迟降低"
                ))
            }
        }
        
        // Bandwidth recommendations
        if network.bandwidthMHz < 80 && network.band != .twoPointFourGHz {
            recommendations.append(Recommendation(
                type: .configurationChange,
                priority: .low,
                title: "启用更宽的信道带宽",
                description: "当前带宽为 \(network.bandwidthMHz)MHz，可考虑启用 80MHz 或 160MHz",
                expectedImprovement: "理论速度提升 2-4 倍"
            ))
        }
        
        return recommendations
    }
    
    public static func calculateDetailedMetrics(for network: NetworkInfo?, in allNetworks: [NetworkInfo]) -> DetailedMetrics {
        guard let network = network else {
            return DetailedMetrics(
                channelUtilization: 0,
                neighboringNetworks: 0,
                sameChannelNetworks: 0,
                overlappingChannels: 0,
                averageNeighborRSSI: 0,
                channelCongestionLevel: .low
            )
        }
        
        let sameChannelNetworks = allNetworks.filter { $0.channel == network.channel && $0.id != network.id }
        let neighboringNetworks = allNetworks.filter { $0.rssi > -80 && $0.id != network.id }
        let overlappingChannels = calculateOverlappingChannels(for: network, in: allNetworks)
        
        let averageRSSI = neighboringNetworks.isEmpty ? 0.0 : 
            Double(neighboringNetworks.map { $0.rssi }.reduce(0, +)) / Double(neighboringNetworks.count)
        
        let utilization = min(100.0, Double(sameChannelNetworks.count) * 15.0)
        
        let congestionLevel: DetailedMetrics.CongestionLevel
        switch sameChannelNetworks.count {
        case 0...1: congestionLevel = .low
        case 2...4: congestionLevel = .moderate
        case 5...8: congestionLevel = .high
        default: congestionLevel = .severe
        }
        
        return DetailedMetrics(
            channelUtilization: utilization,
            neighboringNetworks: neighboringNetworks.count,
            sameChannelNetworks: sameChannelNetworks.count,
            overlappingChannels: overlappingChannels,
            averageNeighborRSSI: averageRSSI,
            channelCongestionLevel: congestionLevel
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func calculateSignalScore(rssi: Int) -> Double {
        switch rssi {
        case -30...0: return 100.0
        case -50...(-31): return 80.0
        case -70...(-51): return 60.0
        case -80...(-71): return 40.0
        case -90...(-81): return 20.0
        default: return 0.0
        }
    }
    
    private static func calculateSNRScore(snr: Int) -> Double {
        switch snr {
        case 40...: return 100.0
        case 25...39: return 80.0
        case 15...24: return 60.0
        case 10...14: return 40.0
        case 5...9: return 20.0
        default: return 0.0
        }
    }
    
    private static func calculateCongestionScore(for network: NetworkInfo, in allNetworks: [NetworkInfo]) -> Double {
        let sameChannelCount = allNetworks.filter { $0.channel == network.channel && $0.id != network.id }.count
        switch sameChannelCount {
        case 0: return 100.0
        case 1: return 80.0
        case 2...3: return 60.0
        case 4...6: return 40.0
        case 7...10: return 20.0
        default: return 0.0
        }
    }
    
    private static func calculateBandwidthScore(bandwidth: Int) -> Double {
        switch bandwidth {
        case 160...: return 100.0
        case 80...159: return 80.0
        case 40...79: return 60.0
        case 20...39: return 40.0
        default: return 20.0
        }
    }
    
    private static func analyzeChannelOptions(for network: NetworkInfo, in allNetworks: [NetworkInfo]) -> (betterChannel: Int?, improvement: Double) {
        let currentChannelNetworks = allNetworks.filter { $0.channel == network.channel && $0.id != network.id }
        
        let availableChannels: [Int]
        switch network.band {
        case .twoPointFourGHz:
            availableChannels = [1, 6, 11] // Non-overlapping channels
        case .fiveGHz:
            availableChannels = [36, 40, 44, 48, 149, 153, 157, 161]
        case .sixGHz:
            availableChannels = [1, 5, 9, 13, 17, 21, 25, 29] // Simplified 6GHz channels
        }
        
        var bestChannel: Int?
        var lowestCongestion = currentChannelNetworks.count
        
        for channel in availableChannels {
            let channelNetworks = allNetworks.filter { $0.channel == channel }
            if channelNetworks.count < lowestCongestion {
                lowestCongestion = channelNetworks.count
                bestChannel = channel
            }
        }
        
        let improvement = Double(currentChannelNetworks.count - lowestCongestion) * 20.0
        return (bestChannel, improvement)
    }
    
    private static func calculateOverlappingChannels(for network: NetworkInfo, in allNetworks: [NetworkInfo]) -> Int {
        let overlappingRange: ClosedRange<Int>
        
        switch network.band {
        case .twoPointFourGHz:
            // 2.4GHz channels overlap significantly
            overlappingRange = (network.channel - 4)...(network.channel + 4)
        case .fiveGHz, .sixGHz:
            // 5GHz and 6GHz channels typically don't overlap as much
            overlappingRange = (network.channel - 1)...(network.channel + 1)
        }
        
        return allNetworks.filter { 
            $0.id != network.id && overlappingRange.contains($0.channel) 
        }.count
    }
}