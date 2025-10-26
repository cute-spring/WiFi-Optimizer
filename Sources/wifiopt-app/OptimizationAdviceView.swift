import SwiftUI

struct OptimizationAdviceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Wi-Fi 优化建议")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                AdviceSection(
                    title: "信号质量 (RSSI, 噪声, SNR)",
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
                        """
                )

                AdviceSection(
                    title: "频段和信道选择",
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
                        """
                )

                AdviceSection(
                    title: "带宽 (Channel Width)",
                    content:
                        """
                        信道带宽决定了数据传输“车道”的宽度。带宽越宽，理论速度越高。

                        - **20 MHz:** 是 2.4 GHz 频段的推荐设置，可以最大限度地减少与邻近网络的干扰。
                        - **40 MHz:** 在 5 GHz 频段下可以提供更高速度，但更容易受到干扰。
                        - **80/160 MHz:** 在 5 GHz 和 6 GHz 频段下提供极高的速度，但会占用更多频谱，对干扰更敏感，且可能影响邻近网络的性能。

                        **优化技巧:**
                        - 对于 2.4 GHz，坚持使用 20 MHz。
                        - 对于 5 GHz，如果您处于干扰较少的环境中，可以尝试使用 40 MHz 或 80 MHz 以获得更高速度。如果遇到连接不稳定的问题，请调回 20 MHz。
                        """
                )

                AdviceSection(
                    title: "安全性 (Security)",
                    content:
                        """
                        强大的加密是保护您网络安全和隐私的屏障。

                        - **WPA3:** 是目前最安全的标准，提供了更强的加密和保护。
                        - **WPA2:** 仍然是安全和广泛使用的标准。
                        - **WPA/WEP/开放网络:** **极不安全**，非常容易被破解。绝对不要使用。

                        **优化技巧:**
                        登录您的路由器管理界面，确保 Wi-Fi 安全性设置为 **WPA2-Personal (AES)** 或 **WPA3-Personal**。如果您的路由器支持，WPA2/WPA3 混合模式也是一个不错的选择，以兼容旧设备。
                        """
                )
                
                AdviceSection(
                    title: "通用网络故障排查",
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
            }
            .padding()
        }
    }
}

struct AdviceSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(.init(content)) // 使用 Markdown
                .font(.body)
                .lineSpacing(5)
        }
        .padding()
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(12)
    }
}