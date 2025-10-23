import SwiftUI
import WiFi_Optimizer

struct CurrentNetworkAnalysisView: View {
    let analysis: NetworkAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(.blue)
                Text("当前网络分析")
                    .font(.headline)
                    .bold()
                Spacer()
                performanceScoreBadge
            }
            
            if let network = analysis.currentNetwork {
                // Current Network Info
                currentNetworkSection(network)
                
                Divider()
                
                // Performance Metrics
                performanceMetricsSection
                
                Divider()
                
                // Interference Factors
                if !analysis.interferenceFactors.isEmpty {
                    interferenceFactorsSection
                    Divider()
                }
                
                // Recommendations
                if !analysis.recommendations.isEmpty {
                    recommendationsSection
                }
            } else {
                Text("未连接到WiFi网络")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var performanceScoreBadge: some View {
        HStack(spacing: 4) {
            Text("\(Int(analysis.performanceScore))")
                .font(.title2)
                .bold()
            Text("分")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(scoreColor.opacity(0.2))
        .foregroundColor(scoreColor)
        .cornerRadius(8)
    }
    
    private var scoreColor: Color {
        switch analysis.performanceScore {
        case 80...100: return .green
        case 60...79: return .blue
        case 40...59: return .orange
        default: return .red
        }
    }
    
    private func currentNetworkSection(_ network: NetworkInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("网络信息")
                .font(.subheadline)
                .bold()
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                networkInfoItem("SSID", network.ssid ?? "未知")
                networkInfoItem("信号强度", "\(network.rssi) dBm")
                networkInfoItem("噪声水平", "\(network.noise) dBm")
                networkInfoItem("信噪比", "\(network.snr) dB")
                networkInfoItem("信道", "\(network.channel)")
                networkInfoItem("频段", network.band.rawValue)
                networkInfoItem("带宽", "\(network.bandwidthMHz) MHz")
                networkInfoItem("安全性", network.security)
            }
            
            // Signal Quality Indicator
            HStack {
                Text("信号质量:")
                    .font(.subheadline)
                Spacer()
                Text(analysis.signalQuality.rawValue)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(Color(analysis.signalQuality.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(analysis.signalQuality.color).opacity(0.2))
                    .cornerRadius(6)
            }
            
            Text(analysis.signalQuality.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func networkInfoItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细指标")
                .font(.subheadline)
                .bold()
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                metricRow("信道利用率", "\(Int(analysis.detailedMetrics.channelUtilization))%", 
                         analysis.detailedMetrics.channelUtilization > 50 ? .orange : .green)
                
                metricRow("邻近网络数", "\(analysis.detailedMetrics.neighboringNetworks)", 
                         analysis.detailedMetrics.neighboringNetworks > 10 ? .orange : .blue)
                
                metricRow("同信道网络", "\(analysis.detailedMetrics.sameChannelNetworks)", 
                         analysis.detailedMetrics.sameChannelNetworks > 3 ? .red : .green)
                
                metricRow("重叠信道数", "\(analysis.detailedMetrics.overlappingChannels)", 
                         analysis.detailedMetrics.overlappingChannels > 5 ? .orange : .blue)
                
                if analysis.detailedMetrics.averageNeighborRSSI != 0 {
                    metricRow("邻近网络平均信号", "\(Int(analysis.detailedMetrics.averageNeighborRSSI)) dBm", .secondary)
                }
                
                metricRow("拥塞等级", analysis.detailedMetrics.channelCongestionLevel.rawValue, 
                         congestionColor(analysis.detailedMetrics.channelCongestionLevel))
            }
        }
    }
    
    private func metricRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }
    
    private func congestionColor(_ level: DetailedMetrics.CongestionLevel) -> Color {
        switch level {
        case .low: return .green
        case .moderate: return .blue
        case .high: return .orange
        case .severe: return .red
        }
    }
    
    private var interferenceFactorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("潜在干扰因素")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.primary)
            }
            
            ForEach(analysis.interferenceFactors.indices, id: \.self) { index in
                let factor = analysis.interferenceFactors[index]
                interferenceFactorCard(factor)
            }
        }
    }
    
    private func interferenceFactorCard(_ factor: InterferenceFactor) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(factor.type.rawValue)
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text(factor.severity.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor(factor.severity).opacity(0.2))
                    .foregroundColor(severityColor(factor.severity))
                    .cornerRadius(4)
            }
            
            Text(factor.description)
                .font(.caption)
                .foregroundColor(.primary)
            
            Text("影响: \(factor.impact)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func severityColor(_ severity: InterferenceFactor.Severity) -> Color {
        switch severity {
        case .low: return .blue
        case .moderate: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                Text("优化建议")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.primary)
            }
            
            ForEach(analysis.recommendations.indices, id: \.self) { index in
                let recommendation = analysis.recommendations[index]
                recommendationCard(recommendation)
            }
        }
    }
    
    private func recommendationCard(_ recommendation: Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(recommendation.title)
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text(recommendation.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor(recommendation.priority).opacity(0.2))
                    .foregroundColor(priorityColor(recommendation.priority))
                    .cornerRadius(4)
            }
            
            Text(recommendation.description)
                .font(.caption)
                .foregroundColor(.primary)
            
            Text("预期改善: \(recommendation.expectedImprovement)")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func priorityColor(_ priority: Recommendation.Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}