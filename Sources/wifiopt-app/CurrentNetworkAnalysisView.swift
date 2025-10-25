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
            Text("网络信息").font(.headline).bold().foregroundColor(.primary)
            
            // Precompute quality information for readability
            let rssiQ = qualityForRSSI(network.rssi)
            let noiseQ = qualityForNoise(network.noise)
            let snrQ = qualityForSNR(network.snr)
            let chQ = qualityForChannel(network.channel, band: network.band)
            let bandQ = qualityForBand(network.band)
            let bwQ = qualityForBandwidth(network.bandwidthMHz, band: network.band)
            let secQ = qualityForSecurity(network.security)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                networkInfoItem("SSID", network.ssid ?? "未知")
                
                networkInfoItem(
                    "信号强度",
                    "\(network.rssi) dBm",
                    reference: rssiQ.reference,
                    quality: (rssiQ.label, rssiQ.color),
                    hint: rssiQ.hint
                )
                
                networkInfoItem(
                    "噪声水平",
                    "\(network.noise) dBm",
                    reference: noiseQ.reference,
                    quality: (noiseQ.label, noiseQ.color),
                    hint: noiseQ.hint
                )
                
                networkInfoItem(
                    "信噪比",
                    "\(network.snr) dB",
                    reference: snrQ.reference,
                    quality: (snrQ.label, snrQ.color),
                    hint: snrQ.hint
                )
                
                networkInfoItem(
                    "信道",
                    "\(network.channel)",
                    reference: chQ.reference,
                    quality: (chQ.label, chQ.color),
                    hint: chQ.hint
                )
                
                networkInfoItem(
                    "频段",
                    network.band.rawValue,
                    reference: bandQ.reference,
                    quality: (bandQ.label, bandQ.color),
                    hint: bandQ.hint
                )
                
                networkInfoItem(
                    "带宽",
                    "\(network.bandwidthMHz) MHz",
                    reference: bwQ.reference,
                    quality: (bwQ.label, bwQ.color),
                    hint: bwQ.hint
                )
                
                networkInfoItem(
                    "安全性",
                    network.security,
                    reference: secQ.reference,
                    quality: (secQ.label, secQ.color),
                    hint: secQ.hint
                )
            }
            
            // Signal Quality Indicator
            HStack {
                Text("信号质量:").font(.headline)
                Spacer()
                Text(analysis.signalQuality.rawValue)
                    .font(.headline)
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

    private func networkInfoItem(_ label: String, _ value: String, reference: String? = nil, quality: (String, Color)? = nil, hint: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                if let quality = quality {
                    StatusChip(quality.0, color: quality.1)
                }
            }
            Text(value)
                .font(.headline)
                .bold()
            if let reference = reference {
                Text(reference)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let hint = hint {
                Text(hint)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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

private struct QualityInfo {
    let label: String
    let color: Color
    let reference: String
    let hint: String
}

private func qualityForRSSI(_ rssi: Int) -> QualityInfo {
    switch rssi {
    case let x where x >= -50:
        return QualityInfo(label: "卓越", color: AppTheme.qualityExcellent, reference: "参考: >= -50 dBm", hint: "非常强的信号，适合高带宽活动")
    case -60..<(-50):
        return QualityInfo(label: "良好", color: AppTheme.qualityGood, reference: "参考: -60…-50 dBm", hint: "稳定连接，流媒体/会议通常可靠")
    case -70..<(-60):
        return QualityInfo(label: "一般", color: AppTheme.qualityFair, reference: "参考: -70…-60 dBm", hint: "轻度使用可，可能出现卡顿")
    case -80..<(-70):
        return QualityInfo(label: "较差", color: AppTheme.qualityPoor, reference: "参考: -80…-70 dBm", hint: "建议靠近路由器或优化布置")
    default:
        return QualityInfo(label: "很差", color: AppTheme.qualityVeryPoor, reference: "参考: < -80 dBm", hint: "连接不稳定，建议改善覆盖")
    }
}

private func qualityForNoise(_ noise: Int) -> QualityInfo {
    switch noise {
    case ..<(-90):
        return QualityInfo(label: "卓越", color: AppTheme.qualityExcellent, reference: "参考: < -90 dBm", hint: "极低噪声，环境非常干净")
    case -90...(-80):
        return QualityInfo(label: "良好", color: AppTheme.qualityGood, reference: "参考: -90…-80 dBm", hint: "低噪声，网络表现稳定")
    case -80...(-70):
        return QualityInfo(label: "一般", color: AppTheme.qualityFair, reference: "参考: -80…-70 dBm", hint: "中等噪声，可能影响吞吐")
    case -70...(-60):
        return QualityInfo(label: "较差", color: AppTheme.qualityPoor, reference: "参考: -70…-60 dBm", hint: "噪声偏高，建议优化环境/信道")
    default:
        return QualityInfo(label: "很差", color: AppTheme.qualityVeryPoor, reference: "参考: > -60 dBm", hint: "噪声很高，强烈建议更换信道/调整设备")
    }
}

private func qualityForSNR(_ snr: Int) -> QualityInfo {
    switch snr {
    case let x where x >= 25:
        return QualityInfo(label: "卓越", color: AppTheme.qualityExcellent, reference: "参考: ≥ 25 dB", hint: "链路质量极佳")
    case 20..<25:
        return QualityInfo(label: "良好", color: AppTheme.qualityGood, reference: "参考: 20…25 dB", hint: "多数场景下表现良好")
    case 13..<20:
        return QualityInfo(label: "一般", color: AppTheme.qualityFair, reference: "参考: 13…20 dB", hint: "轻度干扰，吞吐下降")
    case 10..<13:
        return QualityInfo(label: "较差", color: AppTheme.qualityPoor, reference: "参考: 10…13 dB", hint: "易丢包/卡顿，需优化")
    default:
        return QualityInfo(label: "很差", color: AppTheme.qualityVeryPoor, reference: "参考: < 10 dB", hint: "几乎不可用，建议靠近或换信道")
    }
}

private func qualityForBand(_ band: WiFiBand) -> QualityInfo {
    switch band {
    case .twoPointFourGHz:
        return QualityInfo(label: "一般", color: AppTheme.qualityFair, reference: "参考: 干扰多，覆盖广", hint: "建议仅用于低速设备或远距离覆盖")
    case .fiveGHz:
        return QualityInfo(label: "良好", color: AppTheme.qualityGood, reference: "参考: 干扰少，速度高", hint: "中近距离下优选，兼顾速度与稳定")
    case .sixGHz:
        return QualityInfo(label: "卓越", color: AppTheme.qualityExcellent, reference: "参考: 极低干扰，超高吞吐", hint: "需设备支持，最佳体验")
    }
}

private func qualityForBandwidth(_ bw: Int, band: WiFiBand) -> QualityInfo {
    switch bw {
    case 20:
        let label = (band == .twoPointFourGHz) ? "良好" : "一般"
        let color: Color = (band == .twoPointFourGHz) ? AppTheme.qualityGood : AppTheme.qualityFair
        let hint = (band == .twoPointFourGHz) ? "2.4G 建议 20MHz 以减少重叠" : "有利于远距/墙体穿透，但吞吐较低"
        return QualityInfo(label: label, color: color, reference: "参考: 20 MHz", hint: hint)
    case 40:
        return QualityInfo(label: "良好", color: AppTheme.qualityGood, reference: "参考: 40 MHz", hint: "在较干净环境下提升吞吐")
    case 80:
        return QualityInfo(label: "卓越", color: AppTheme.qualityExcellent, reference: "参考: 80 MHz", hint: "5G 下常见，高吞吐")
    case 160:
        return QualityInfo(label: "卓越", color: AppTheme.qualityExcellent, reference: "参考: 160 MHz", hint: "需要干净频谱，可能涉及 DFS 信道")
    default:
        return QualityInfo(label: "一般", color: AppTheme.qualityFair, reference: "参考: \(bw) MHz", hint: "带宽与环境/设备能力相关")
    }
}

private func qualityForSecurity(_ sec: String) -> QualityInfo {
    let s = sec.lowercased()
    if s.contains("wpa3") { return QualityInfo(label: "卓越", color: AppTheme.qualityExcellent, reference: "参考: WPA3", hint: "最新标准，安全性最佳") }
    if s.contains("wpa2") { return QualityInfo(label: "良好", color: AppTheme.qualityGood, reference: "参考: WPA2", hint: "常见标准，安全性可靠") }
    if s.contains("wpa") { return QualityInfo(label: "一般", color: AppTheme.qualityFair, reference: "参考: WPA", hint: "较旧标准，建议升级") }
    if s.contains("wep") { return QualityInfo(label: "较差", color: AppTheme.qualityPoor, reference: "参考: WEP", hint: "已不安全，强烈建议更换") }
    if s.contains("open") { return QualityInfo(label: "很差", color: AppTheme.qualityVeryPoor, reference: "参考: 开放网络", hint: "不加密，谨慎使用") }
    return QualityInfo(label: "未知", color: AppTheme.muted, reference: "参考: \(sec)", hint: "无法识别，请确认路由器设置")
}

private func qualityForChannel(_ ch: Int, band: WiFiBand) -> QualityInfo {
    switch band {
    case .twoPointFourGHz:
        let preferred = [1,6,11]
        if preferred.contains(ch) {
            return QualityInfo(label: "卓越", color: AppTheme.qualityExcellent, reference: "参考: 1/6/11", hint: "减少重叠与互扰")
        } else {
            return QualityInfo(label: "一般", color: AppTheme.qualityFair, reference: "参考: 1/6/11 优先", hint: "可能与邻居重叠，建议调整")
        }
    case .fiveGHz:
        return QualityInfo(label: "良好", color: AppTheme.qualityGood, reference: "参考: 36–165 (非 DFS 优先)", hint: "尽量避开拥挤信道")
    case .sixGHz:
        return QualityInfo(label: "卓越", color: AppTheme.qualityExcellent, reference: "参考: 6G 信道", hint: "干扰极低，吞吐高")
    }
}