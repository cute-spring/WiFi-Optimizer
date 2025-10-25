import SwiftUI
import WiFi_Optimizer

struct CurrentNetworkAnalysisView: View {
    let analysis: NetworkAnalysis
    
    var body: some View {
        VStack(spacing: AppTheme.sectionSpacing) {
            // Header + current network card
            SectionCard(title: "当前网络分析") {
                HStack {
                    Image(systemName: "wifi").foregroundColor(.blue)
                    Text("当前网络分析").font(.headline).bold()
                    Spacer()
                    performanceScoreBadge
                }
                
                if let network = analysis.currentNetwork {
                    currentNetworkSection(network)
                } else {
                    Text("未连接到WiFi网络")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            if analysis.currentNetwork != nil {
                // Performance Metrics
                performanceMetricsSection
                
                // Interference Factors
                if !analysis.interferenceFactors.isEmpty { interferenceFactorsSection }
                
                // Recommendations
                if !analysis.recommendations.isEmpty { recommendationsSection }
            }
        }
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
        VStack(alignment: .leading, spacing: 12) {
            Text("网络信息").font(.subheadline).bold().foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
                Text("信号质量:").font(.subheadline)
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
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner, style: .continuous))
    }

    private var performanceMetricsSection: some View {
        SectionCard(title: "详细指标") {
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
            Text(label).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline).bold().foregroundColor(color)
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
        SectionCard(title: "潜在干扰因素") {
            ForEach(analysis.interferenceFactors.indices, id: \.self) { index in
                let factor = analysis.interferenceFactors[index]
                interferenceFactorCard(factor)
            }
        }
    }
    
    private func interferenceFactorCard(_ factor: InterferenceFactor) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
                Text(factor.type.rawValue).font(.subheadline).bold()
                Spacer()
                Text(factor.severity.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor(factor.severity).opacity(0.2))
                    .foregroundColor(severityColor(factor.severity))
                    .cornerRadius(4)
            }
            Text(factor.description).font(.caption).foregroundColor(.primary)
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner, style: .continuous))
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
        SectionCard(title: "优化建议") {
            ForEach(analysis.recommendations.indices, id: \.self) { index in
                let recommendation = analysis.recommendations[index]
                recommendationCard(recommendation)
            }
        }
    }
    
    private func recommendationCard(_ recommendation: Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "lightbulb").foregroundColor(.yellow)
                Text(recommendation.title).font(.subheadline).bold()
                Spacer()
                Text(recommendation.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor(recommendation.priority).opacity(0.2))
                    .foregroundColor(priorityColor(recommendation.priority))
                    .cornerRadius(4)
            }
            Text(recommendation.description).font(.caption).foregroundColor(.primary)
            Text("预期改善: \(recommendation.expectedImprovement)")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner, style: .continuous))
    }
    
    private func priorityColor(_ priority: Recommendation.Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}