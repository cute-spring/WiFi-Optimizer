import SwiftUI
import WiFi_Optimizer

struct QualityReferenceView: View {
    @EnvironmentObject var model: ScannerModel



    // Current network snapshot
    private var currentRSSI: Int? { model.current?.rssi }
    private var currentNoise: Int? { model.current?.noise }
    private var currentSNR: Int? { model.current?.snr }
    private var currentChannel: Int? { model.current?.channel }
    private var currentBand: WiFiBand? { model.networkAnalysis?.currentNetwork?.band ?? model.current?.band }
    private var currentBandwidth: Int? { model.networkAnalysis?.currentNetwork?.bandwidthMHz }
    private var currentSecurity: String? { model.networkAnalysis?.currentNetwork?.security }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 12) {
                    overviewSection
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
                        rssiCard
                        noiseCard
                        snrCard
                        bandCard
                        channelCard
                        bandwidthCard
                        securityCard
                    }
                }
            }
            .padding([.horizontal, .bottom], 12)
        }
    }

    // MARK: - Columns
    @ViewBuilder private var overviewSection: some View {
        SectionCard(title: "当前网络一览") {
            if let iface = model.current {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 8)], spacing: 8) {
                    summaryItem("RSSI", "\(iface.rssi) dBm", quality: qualityForRSSI(iface.rssi))
                    summaryItem("Noise", "\(iface.noise) dBm", quality: qualityForNoise(iface.noise))
                    summaryItem("SNR", "\(iface.snr) dB", quality: qualityForSNR(iface.snr))

                    let bandQ = currentBand.map { qualityForBand($0) }
                    summaryItem("频段", bandLabel(currentBand), quality: bandQ)

                    let chQ = QualityInfo(label: channelQualityLabel(), color: channelQualityColor(), reference: channelReference(), hint: channelHint())
                    summaryItem("信道", currentChannel.map { "\($0)" } ?? "未知", quality: chQ)

                    let bwQ = (currentBandwidth != nil && currentBand != nil) ? qualityForBandwidth(currentBandwidth!, band: currentBand!) : nil
                    summaryItem("带宽", currentBandwidth.map { "\($0) MHz" } ?? "未知", quality: bwQ)

                    let secQ = currentSecurity.map { qualityForSecurity($0) }
                    summaryItem("安全性", currentSecurity ?? "未知", quality: secQ)
                }
            } else {
                Text("未连接到WiFi网络")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }


    @ViewBuilder private var rssiCard: some View {
        let levels: [QualityLevel] = [
            .init(label: "卓越", range: "≥ -50 dBm", color: AppTheme.qualityExcellent, highlight: isCurrentRSSILabel("卓越")),
            .init(label: "良好", range: "-60 … -50 dBm", color: AppTheme.qualityGood, highlight: isCurrentRSSILabel("良好")),
            .init(label: "一般", range: "-70 … -60 dBm", color: AppTheme.qualityFair, highlight: isCurrentRSSILabel("一般")),
            .init(label: "较差", range: "-80 … -70 dBm", color: AppTheme.qualityPoor, highlight: isCurrentRSSILabel("较差")),
            .init(label: "很差", range: "< -80 dBm", color: AppTheme.qualityVeryPoor, highlight: isCurrentRSSILabel("很差"))
        ]
        SegmentedBarCard(
            title: "RSSI（信号强度）",
            value: currentRSSI,
            unit: "dBm",
            levels: levels,
            description: "信号强度越高越好。优秀的信号是Wi-Fi速度和稳定性的基础。"
        )
    }

    @ViewBuilder private var noiseCard: some View {
        let levels: [QualityLevel] = [
            .init(label: "卓越", range: "< -90 dBm", color: AppTheme.qualityExcellent, highlight: isCurrentNoiseLabel("卓越")),
            .init(label: "良好", range: "-90 … -80 dBm", color: AppTheme.qualityGood, highlight: isCurrentNoiseLabel("良好")),
            .init(label: "一般", range: "-80 … -70 dBm", color: AppTheme.qualityFair, highlight: isCurrentNoiseLabel("一般")),
            .init(label: "较差", range: "-70 … -60 dBm", color: AppTheme.qualityPoor, highlight: isCurrentNoiseLabel("较差")),
            .init(label: "很差", range: "> -60 dBm", color: AppTheme.qualityVeryPoor, highlight: isCurrentNoiseLabel("很差"))
        ]
        SegmentedBarCard(
            title: "噪声（Noise）",
            value: currentNoise,
            unit: "dBm",
            levels: levels,
            description: "噪声越低越好。高噪声会干扰Wi-Fi信号，导致性能下降。"
        )
    }

    @ViewBuilder private var snrCard: some View {
        let levels: [QualityLevel] = [
            .init(label: "卓越", range: "≥ 25 dB", color: AppTheme.qualityExcellent, highlight: isCurrentSNRLabel("卓越")),
            .init(label: "良好", range: "20 … 25 dB", color: AppTheme.qualityGood, highlight: isCurrentSNRLabel("良好")),
            .init(label: "一般", range: "13 … 20 dB", color: AppTheme.qualityFair, highlight: isCurrentSNRLabel("一般")),
            .init(label: "较差", range: "10 … 13 dB", color: AppTheme.qualityPoor, highlight: isCurrentSNRLabel("较差")),
            .init(label: "很差", range: "< 10 dB", color: AppTheme.qualityVeryPoor, highlight: isCurrentSNRLabel("很差"))
        ]
        SegmentedBarCard(
            title: "SNR（信噪比）",
            value: currentSNR,
            unit: "dB",
            levels: levels,
            description: "信噪比越高越好。它直接反映了信号与噪声的差距，是衡量链路质量的关键指标。"
        )
    }

    @ViewBuilder private var bandCard: some View {
        SectionCard(title: "频段（Band）") {
            referenceGrid(rows: [
                RowData(label: "一般", value: "2.4 GHz", color: AppTheme.qualityFair, highlight: currentBand == .twoPointFourGHz),
                RowData(label: "良好", value: "5 GHz", color: AppTheme.qualityGood, highlight: currentBand == .fiveGHz),
                RowData(label: "卓越", value: "6 GHz", color: AppTheme.qualityExcellent, highlight: currentBand == .sixGHz)
            ])
            Text("注：部分地区 DFS 信道受雷达检测影响，可能临时不可用")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text("说明：2.4G 覆盖广但干扰多；5G 干扰少速度高；6G 干扰极低、吞吐最高（需设备支持）")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder private var channelCard: some View {
        SectionCard(title: "信道（Channel）") {
            referenceGrid(rows: [
                RowData(label: "卓越", value: "2.4 GHz 优先 1 / 6 / 11", color: AppTheme.qualityExcellent, highlight: (currentBand == .twoPointFourGHz) && isPreferred24(currentChannel)),
                RowData(label: "一般", value: "2.4 GHz 使用其它信道", color: AppTheme.qualityFair, highlight: (currentBand == .twoPointFourGHz) && !isPreferred24(currentChannel)),
                RowData(label: "良好", value: "5 GHz 选择非 DFS 信道", color: AppTheme.qualityGood, highlight: (currentBand == .fiveGHz) && isNonDFS(currentChannel)),
                RowData(label: "卓越", value: "6 GHz", color: AppTheme.qualityExcellent, highlight: (currentBand == .sixGHz))
            ])
            Text("说明：合理选择信道可显著降低重叠与互扰；DFS 信道可能受雷达占用限制")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder private var bandwidthCard: some View {
        SectionCard(title: "带宽（Channel Width）") {
            referenceGrid(rows: [
                RowData(label: "良好", value: "20 MHz（2.4G）", color: AppTheme.qualityGood, highlight: currentBandwidth == 20 && currentBand == .twoPointFourGHz),
                RowData(label: "一般", value: "20 MHz（5/6G）", color: AppTheme.qualityFair, highlight: currentBandwidth == 20 && (currentBand == .fiveGHz || currentBand == .sixGHz)),
                RowData(label: "良好", value: "40 MHz", color: AppTheme.qualityGood, highlight: currentBandwidth == 40),
                RowData(label: "卓越", value: "80 / 160 MHz", color: AppTheme.qualityExcellent, highlight: currentBandwidth == 80 || currentBandwidth == 160)
            ])
            Text("说明：带宽越大吞吐越高，但更易受干扰；2.4G 通常建议 20MHz 以减少重叠")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder private var securityCard: some View {
        SectionCard(title: "安全性（Security）") {
            referenceGrid(rows: [
                RowData(label: "卓越", value: "WPA3", color: AppTheme.qualityExcellent, highlight: matchesSecurity("wpa3")),
                RowData(label: "良好", value: "WPA2", color: AppTheme.qualityGood, highlight: matchesSecurity("wpa2")),
                RowData(label: "一般", value: "WPA", color: AppTheme.qualityFair, highlight: matchesSecurity("wpa")),
                RowData(label: "较差", value: "WEP", color: AppTheme.qualityPoor, highlight: matchesSecurity("wep")),
                RowData(label: "很差", value: "开放（Open）", color: AppTheme.qualityVeryPoor, highlight: matchesSecurity("open"))
            ])
            Text("说明：未知或无法识别的加密方式保持灰色，仅供参考")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }


    private func summaryItem(_ label: String, _ value: String, quality: QualityInfo?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Spacer()
                if let q = quality {
                    StatusChip(q.label, color: q.color)
                }
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner, style: .continuous))
    }

    private func referenceRow(label: String, value: String, color: Color, highlight: Bool) -> some View {
        HStack(spacing: 10) {
            StatusChip(label, color: color)
            Text(value)
                .font(.system(size: 17, weight: .bold))
        }
        .padding(10)
        .background(highlight ? color.opacity(0.18) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(highlight ? color.opacity(0.7) : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - New Visual Component

    private struct QualityLevel: Identifiable {
        let id = UUID()
        let label: String
        let range: String
        let color: Color
        let highlight: Bool
    }

    @ViewBuilder
    private func SegmentedBarCard(
        title: String,
        value: Int?,
        unit: String,
        levels: [QualityLevel],
        description: String
    ) -> some View {
        SectionCard(title: title) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let v = value {
                        Text("\(v)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(levels.first(where: { $0.highlight })?.color ?? .primary)
                        Text(unit)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    } else {
                        Text("未知")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 2) {
                    ForEach(levels) { level in
                        Rectangle()
                            .fill(level.color)
                            .overlay(
                                level.highlight ?
                                    Rectangle().stroke(Color.primary.opacity(0.8), lineWidth: 3) :
                                    nil
                            )
                    }
                }
                .frame(height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(levels) { level in
                        HStack(spacing: 8) {
                            Circle().fill(level.color).frame(width: 10, height: 10)
                            Text(level.label)
                                .font(.system(size: 15, weight: .medium))
                                .frame(width: 40, alignment: .leading)
                            Text(level.range)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    // Grid-based reference table rows
    private struct RowData: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let color: Color
        let highlight: Bool
    }

    @ViewBuilder private func referenceGrid(rows: [RowData]) -> some View {
        if #available(macOS 13.0, *) {
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
                ForEach(rows) { r in
                    GridRow {
                        StatusChip(r.label, color: r.color)
                        Text(r.value)
                            .font(.system(size: 19, weight: .bold))
                    }
                    .padding(8)
                    .background(r.highlight ? r.color.opacity(0.18) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(r.highlight ? r.color.opacity(0.7) : Color.clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(rows) { r in
                    HStack(spacing: 8) {
                        StatusChip(r.label, color: r.color)
                        Text(r.value)
                            .font(.system(size: 19, weight: .bold))
                        Spacer()
                    }
                    .padding(8)
                    .background(r.highlight ? r.color.opacity(0.18) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(r.highlight ? r.color.opacity(0.7) : Color.clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func isCurrentRSSILabel(_ target: String) -> Bool {
        guard let r = currentRSSI else { return false }
        return qualityForRSSI(r).label == target
    }
    private func isCurrentNoiseLabel(_ target: String) -> Bool {
        guard let n = currentNoise else { return false }
        return qualityForNoise(n).label == target
    }
    private func isCurrentSNRLabel(_ target: String) -> Bool {
        guard let s = currentSNR else { return false }
        return qualityForSNR(s).label == target
    }
    private func matchesSecurity(_ keyword: String) -> Bool {
        guard let sec = currentSecurity?.lowercased() else { return false }
        return sec.contains(keyword)
    }
    private func isPreferred24(_ ch: Int?) -> Bool {
        guard let c = ch else { return false }
        return [1,6,11].contains(c)
    }
    private func isNonDFS(_ ch: Int?) -> Bool {
        guard let c = ch else { return false }
        // Common non-DFS 5 GHz channels: 36-48, 149-165
        return (36...48).contains(c) || (149...165).contains(c)
    }

    private func channelQualityLabel() -> String {
        guard let band = currentBand else { return "未知" }
        switch band {
        case .twoPointFourGHz:
            return isPreferred24(currentChannel) ? "卓越" : "一般"
        case .fiveGHz:
            return isNonDFS(currentChannel) ? "良好" : "一般"
        case .sixGHz:
            return "卓越"
        }
    }
    private func channelQualityColor() -> Color {
        let label = channelQualityLabel()
        switch label {
        case "卓越": return AppTheme.qualityExcellent
        case "良好": return AppTheme.qualityGood
        case "一般": return AppTheme.qualityFair
        case "较差": return AppTheme.qualityPoor
        default: return AppTheme.qualityVeryPoor
        }
    }
    private func channelReference() -> String {
        guard let band = currentBand else { return "参考: 未知" }
        switch band {
        case .twoPointFourGHz: return "参考: 1/6/11 优先"
        case .fiveGHz: return "参考: 非 DFS 信道优先"
        case .sixGHz: return "参考: 6G 信道"
        }
    }
    private func channelHint() -> String {
        guard let band = currentBand else { return "" }
        switch band {
        case .twoPointFourGHz: return "减少重叠与互扰"
        case .fiveGHz:
            return isNonDFS(currentChannel) ? "尽量避开拥挤信道" : "当前为 DFS 信道，可能受雷达检测影响"
        case .sixGHz: return "干扰极低，吞吐高"
        }
    }

    private func bandLabel(_ band: WiFiBand?) -> String {
        switch band {
            case .twoPointFourGHz: return "2.4 GHz"
            case .fiveGHz: return "5 GHz"
            case .sixGHz: return "6 GHz"
            case .none: return "未知"
        }
    }

    // MARK: - Quality functions (consistent with CurrentNetworkAnalysisView)
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
}