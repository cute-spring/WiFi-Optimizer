import SwiftUI
import WiFi_Optimizer

struct OptimizationAdviceView: View {
    let selectedNetwork: NetworkInfo?

    private var advices: [AdviceSection] {
        buildAdvices(for: selectedNetwork)
    }

    @State private var expandedAdvice: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Wi-Fi 优化建议")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                ForEach(advices) { advice in
                    VStack(alignment: .leading) {
                        HStack(spacing: 15) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.7))
                                .rotationEffect(.degrees(expandedAdvice == advice.id ? 90 : 0))

                            Image(systemName: advice.icon)
                                .font(.title2)
                                .foregroundColor(advice.highlightColor)
                                .frame(width: 35, height: 35)
                                .background(advice.highlightColor.opacity(0.12))
                                .clipShape(Circle())

                            Text(advice.title)
                                .font(.title2)
                                .fontWeight(.semibold)

                            if advice.isActionable {
                                Spacer()
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if expandedAdvice == advice.id {
                                    expandedAdvice = nil
                                } else {
                                    expandedAdvice = advice.id
                                }
                            }
                        }

                        if expandedAdvice == advice.id {
                            Text(.init(advice.content)) // 使用 Markdown
                                .font(.body)
                                .lineSpacing(6)
                                .padding(.top, 10)
                                .padding(.horizontal, 4)
                                .padding(.leading, 50) // Approximate indent
                        }
                    }
                    .padding()
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(advice.isActionable ? advice.highlightColor : Color.clear, lineWidth: 1.5)
                    )
                }
            }
            .padding()
        }
        .onAppear {
            // Auto-expand the first actionable advice
            if let firstActionable = advices.first(where: { $0.isActionable }) {
                expandedAdvice = firstActionable.id
            }
        }
        .onChange(of: selectedNetwork) { _ in
            // Re-evaluate which advice to expand when the network changes
            if let firstActionable = advices.first(where: { $0.isActionable }) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAdvice = firstActionable.id
                }
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAdvice = nil
                }
            }
        }
    }
}

struct AdviceSection: Identifiable {
    var id: String { title }
    let title: String
    let icon: String
    let content: String
    var isActionable: Bool = false
    var isExpanded: Bool = false
    var highlightColor: Color = .accentColor
}

// swiftlint:disable:next file_length
private func buildAdvices(for network: NetworkInfo?) -> [AdviceSection] {
    guard let network = network else {
        // Return a default or empty state if no network is selected
        return [
            AdviceSection(
                title: "没有选择网络",
                icon: "wifi.slash",
                content: "请从左侧列表中选择一个网络以查看优化建议。",
                isExpanded: true
            )
        ]
    }

    let rssiQuality = qualityForRSSI(network.rssi)
    let noiseQuality = qualityForNoise(network.noise)
    let snrQuality = qualityForSNR(network.snr)
    let channelQuality = qualityForChannel(network.channel, band: network.band)
    let securityQuality = qualityForSecurity(network.security)
    let bandwidthQuality = qualityForBandwidth(network.bandwidthMHz, band: network.band)

    let adviceList = [
        AdviceSection(
            title: "信号质量 (RSSI, 噪声, SNR)",
            icon: "chart.bar.xaxis",
            content:
                """
                信号质量是稳定、高速 Wi-Fi 的基石。RSSI、噪声和 SNR 是衡量信号质量的三个核心指标。

                - **RSSI (信号强度):** 信号强度越高越好。理想值应高于 -60 dBm。
                  **优化技巧:**
                  1.  将路由器放置在房屋的中心位置，并尽量置于高处。
                  2.  减少路由器与设备之间的物理障碍，如墙壁、金属物体和大型家具。
                  3.  让路由器远离其他电子设备，特别是微波炉、无绳电话和蓝牙设备，它们会产生干扰。

                - **噪声 (Noise):** 噪声水平越低越好。理想值应低于 -80 dBm。高噪声会严重干扰您的 Wi-Fi 信号。
                  **优化技巧:**
                  1.  识别并关闭或移走产生射频干扰的设备。
                  2.  如果邻近的 Wi-Fi 网络过多，请尝试切换到干扰较少的信道。

                - **SNR (信噪比):** 信噪比越高越好，它直接反映了信号与背景噪声的差距。理想值应高于 25 dB。
                  **优化技巧:**
                  SNR 是 RSSI 和噪声共同作用的结果。通过提升 RSSI 和降低噪声，您的 SNR 自然会得到改善。
                """,
            isActionable: ([rssiQuality, noiseQuality, snrQuality] as [QualityResult]).contains(where: { $0.isActionable }),
            isExpanded: ([rssiQuality, noiseQuality, snrQuality] as [QualityResult]).contains(where: { $0.isActionable }),
            highlightColor: poorestQuality(among: [rssiQuality, noiseQuality, snrQuality]).color
        ),
        AdviceSection(
            title: "频段和信道选择",
            icon: "wifi.circle",
            content:
                """
                正确选择频段和信道是避免拥堵、提升速度的关键。

                - **频段 (Band):**
                  - **2.4 GHz:** 覆盖范围广，穿墙能力强，但速度较慢且非常拥挤，容易受到来自邻居 Wi-Fi 和其他家用电器的干扰。
                  - **5 GHz:** 速度快得多，干扰少，但覆盖范围和穿墙能力不如 2.4 GHz。
                  - **6 GHz (Wi-Fi 6E):** 速度最快，干扰极低，但需要路由器和终端设备都支持 Wi-Fi 6E。

                  **优化技巧:**
                  如果您的设备支持，请优先连接到 5 GHz 或 6 GHz 网络以获得最佳性能。将需要高速稳定连接的设备（如游戏机、智能电视）连接到这些频段。

                - **信道 (Channel):**
                  - **2.4 GHz:** 为避免信道重叠造成的干扰，请务必使用 **1, 6, 或 11** 这三个互不重叠的信道之一。
                  - **5 GHz:** 信道选择更多，不易重叠。但需注意 **DFS (动态频率选择)** 信道。这些信道可能会被雷达（如气象雷达）占用，导致 Wi-Fi 临时中断。如果稳定性是首要考虑，可以选择非 DFS 信道。

                  **优化技巧:**
                  登录您的路由器管理界面，将信道设置从“自动”更改为推荐的固定信道。
                """,
            isActionable: channelQuality.isActionable,
            isExpanded: channelQuality.isActionable,
            highlightColor: channelQuality.color
        ),
        AdviceSection(
            title: "带宽 (Channel Width)",
            icon: "arrow.left.and.right.square",
            content:
                """
                信道带宽决定了数据传输“车道”的宽度。带宽越宽，理论速度越高。

                - **20 MHz:** 是 2.4 GHz 频段的推荐设置，可以最大限度地减少与邻近网络的干扰。
                - **40 MHz:** 在 5 GHz 频段下可以提供更高速度，但更容易受到干扰。
                - **80/160 MHz:** 在 5 GHz 和 6 GHz 频段下提供极高的速度，但会占用更多频谱，对干扰更敏感，且可能影响邻近网络的性能。

                **优化技巧:**
                - 对于 2.4 GHz，坚持使用 20 MHz。
                - 对于 5 GHz，如果您处于干扰较少的环境中，可以尝试使用 40 MHz 或 80 MHz 以获得更高速度。如果遇到连接不稳定的问题，请调回 20 MHz。
                """,
            isActionable: bandwidthQuality.isActionable,
            isExpanded: bandwidthQuality.isActionable,
            highlightColor: bandwidthQuality.color
        ),
        AdviceSection(
            title: "安全性 (Security)",
            icon: "lock.shield",
            content:
                """
                强大的加密是保护您网络安全和隐私的屏障。

                - **WPA3:** 是目前最安全的标准，提供了更强的加密和保护。
                - **WPA2:** 仍然是安全和广泛使用的标准。
                - **WPA/WEP/开放网络:** **极不安全**，非常容易被破解。绝对不要使用。

                **优化技巧:**
                登录您的路由器管理界面，确保 Wi-Fi 安全性设置为 **WPA2-Personal (AES)** 或 **WPA3-Personal**。如果您的路由器支持，WPA2/WPA3 混合模式也是一个不错的选择，以兼容旧设备。
                """,
            isActionable: securityQuality.isActionable,
            isExpanded: securityQuality.isActionable,
            highlightColor: securityQuality.color
        ),
        AdviceSection(
            title: "通用网络故障排查",
            icon: "questionmark.circle",
            content:
                """
                如果遇到网络问题，可以尝试以下基本步骤：

                1.  **重启设备:** 这是最简单也最有效的“万能”方法。请重启您的路由器、光猫和终端设备。
                2.  **更新固件:** 确保您的路由器固件是最新版本。制造商会通过固件更新来修复错误和提升性能。
                3.  **检查带宽占用:** 检查是否有某个设备正在进行大量的下载或上传，占用了所有带宽。
                4.  **有线连接:** 对于需要最稳定连接的设备（如台式电脑、游戏主机），尽可能使用以太网有线连接。
                5.  **联系 ISP:** 如果以上方法都无法解决问题，问题可能出在您的互联网服务提供商 (ISP) 身上。请联系他们进行检查。
                """
        )
    ]

    return adviceList
}

// MARK: - Quality Evaluation Logic
// (Based on rules from QualityReferenceView)

private struct QualityResult {
    let level: QualityLevel
    let color: Color
    let isActionable: Bool
}

private enum QualityLevel: Int, Comparable {
    case excellent, good, fair, poor, veryPoor

    // Conformance to Comparable
    static func < (lhs: QualityLevel, rhs: QualityLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var isActionable: Bool {
        return self >= .fair
    }
}

private func qualityForRSSI(_ rssi: Int) -> QualityResult {
    switch rssi {
    case -50...0:
        return .init(level: .excellent, color: AppTheme.qualityExcellent, isActionable: false)
    case -67...(-51):
        return .init(level: .good, color: AppTheme.qualityGood, isActionable: false)
    case -75...(-68):
        return .init(level: .fair, color: AppTheme.qualityFair, isActionable: true)
    case -85...(-76):
        return .init(level: .poor, color: AppTheme.qualityPoor, isActionable: true)
    default:
        return .init(level: .veryPoor, color: AppTheme.qualityVeryPoor, isActionable: true)
    }
}

private func qualityForNoise(_ noise: Int) -> QualityResult {
    switch noise {
    case ..<(-90):
        return .init(level: .excellent, color: AppTheme.qualityExcellent, isActionable: false)
    case (-90)...(-80):
        return .init(level: .good, color: AppTheme.qualityGood, isActionable: false)
    case (-79)...(-70):
        return .init(level: .fair, color: AppTheme.qualityFair, isActionable: true)
    default:
        return .init(level: .poor, color: AppTheme.qualityPoor, isActionable: true)
    }
}

private func qualityForSNR(_ snr: Int) -> QualityResult {
    switch snr {
    case 40...:
        return .init(level: .excellent, color: AppTheme.qualityExcellent, isActionable: false)
    case 25...39:
        return .init(level: .good, color: AppTheme.qualityGood, isActionable: false)
    case 15...24:
        return .init(level: .fair, color: AppTheme.qualityFair, isActionable: true)
    case 10...14:
        return .init(level: .poor, color: AppTheme.qualityPoor, isActionable: true)
    default:
        return .init(level: .veryPoor, color: AppTheme.qualityVeryPoor, isActionable: true)
    }
}

private func qualityForChannel(_ channel: Int, band: WiFiBand?) -> QualityResult {
    guard let band = band else {
        return .init(level: .fair, color: AppTheme.qualityFair, isActionable: true)
    }
    switch band {
    case .twoPointFourGHz:
        if [1, 6, 11].contains(channel) {
            return .init(level: .excellent, color: AppTheme.qualityExcellent, isActionable: false)
        } else {
            return .init(level: .fair, color: AppTheme.qualityFair, isActionable: true)
        }
    case .fiveGHz:
        // Non-DFS channels are preferred for stability
        if (36...48).contains(channel) || (149...165).contains(channel) {
            return .init(level: .good, color: AppTheme.qualityGood, isActionable: false)
        } else {
            return .init(level: .fair, color: AppTheme.qualityFair, isActionable: true) // DFS channel
        }
    case .sixGHz:
        return .init(level: .excellent, color: AppTheme.qualityExcellent, isActionable: false)
    }
}

private func qualityForSecurity(_ security: String?) -> QualityResult {
    guard let security = security else {
        return .init(level: .veryPoor, color: AppTheme.qualityVeryPoor, isActionable: true)
    }
    switch security {
    case "WPA3 Personal", "WPA3 Enterprise":
        return .init(level: .excellent, color: AppTheme.qualityExcellent, isActionable: false)
    case "WPA2 Personal", "WPA2 Enterprise", "WPA2/WPA3 Personal":
        return .init(level: .good, color: AppTheme.qualityGood, isActionable: false)
    case "WPA Personal", "WPA/WPA2":
        return .init(level: .poor, color: AppTheme.qualityPoor, isActionable: true)
    case "WEP", "Open":
        return .init(level: .veryPoor, color: AppTheme.qualityVeryPoor, isActionable: true)
    default:
        return .init(level: .fair, color: AppTheme.qualityFair, isActionable: false) // Treat unknown as neutral
    }
}

private func qualityForBandwidth(_ width: Int?, band: WiFiBand?) -> QualityResult {
    guard let width = width, let band = band else {
        return .init(level: .fair, color: AppTheme.qualityFair, isActionable: false) // Neutral if unknown
    }
    switch band {
    case .twoPointFourGHz:
        if width > 20 {
            return .init(level: .fair, color: AppTheme.qualityFair, isActionable: true) // 40MHz on 2.4 is not ideal
        } else {
            return .init(level: .good, color: AppTheme.qualityGood, isActionable: false)
        }
    case .fiveGHz, .sixGHz:
        if width < 40 {
            return .init(level: .fair, color: AppTheme.qualityFair, isActionable: true) // Narrower than optimal
        } else {
            return .init(level: .good, color: AppTheme.qualityGood, isActionable: false)
        }
    }
}

private func poorestQuality(among results: [QualityResult]) -> QualityResult {
    return results.min(by: { $0.level.rawValue < $1.level.rawValue }) ?? .init(level: .excellent, color: .gray, isActionable: false)
}