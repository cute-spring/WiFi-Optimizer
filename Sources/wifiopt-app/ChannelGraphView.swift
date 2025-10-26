import SwiftUI
import WiFi_Optimizer

struct ChannelGraphView: View {
    let band: WiFiBand
    let networks: [NetworkInfo]
    let currentBSSID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Canvas { context, size in
                var rect = CGRect(origin: .zero, size: size)
                rect = rect.insetBy(dx: 8, dy: 8)
                drawGrid(context: &context, rect: rect)
                drawNetworks(context: &context, rect: rect)
            }
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
        }
    }

    private func channelRange() -> (min: Int, max: Int, step: Int) {
        switch band {
        case .twoPointFourGHz:
            return (1, 14, 1)
        case .fiveGHz:
            // 5 GHz common channels 36..165; draw grid every 4 channel numbers
            return (36, 165, 4)
        case .sixGHz:
            // Placeholder; not drawn in dashboard yet
            return (1, 233, 8)
        }
    }

    private func xForChannel(_ ch: Int, in rect: CGRect) -> CGFloat {
        let (minCh, maxCh, _) = channelRange()
        let clamped = max(min(ch, maxCh), minCh)
        let span = CGFloat(maxCh - minCh)
        if span == 0 { return rect.minX }
        return rect.minX + ((CGFloat(clamped - minCh) / span) * rect.width)
    }

    private func heightForRSSI(_ rssi: Int, in rect: CGRect) -> CGFloat {
        let minRSSI = -100
        let maxRSSI = -30
        let clamped = max(min(rssi, maxRSSI), minRSSI)
        let frac = CGFloat(clamped - minRSSI) / CGFloat(maxRSSI - minRSSI)
        return max(4, frac * rect.height)
    }

    private func widthForBandwidth(_ mhz: Int, in rect: CGRect) -> CGFloat {
        // Approximate width in channel-number units.
        // 2.4 GHz: channels spaced ~5 MHz; 20 MHz spans ~4 channel numbers.
        // 5 GHz: primary channels every 4 numbers; 20 MHz spans ~4 numbers.
        let baseUnits = max(1, mhz / 20) // 20MHz increments
        let multiplier: Int
        switch band {
        case .twoPointFourGHz: multiplier = 4
        case .fiveGHz: multiplier = 4
        case .sixGHz: multiplier = 8 // rough placeholder for 6GHz wider spacing
        }
        let units = baseUnits * multiplier
        let (minCh, maxCh, _) = channelRange()
        let span = CGFloat(maxCh - minCh)
        if span == 0 { return 8 }
        let unitWidth = rect.width / span
        return max(8, CGFloat(units) * unitWidth)
    }

    private func drawGrid(context: inout GraphicsContext, rect: CGRect) {
        let (minCh, maxCh, step) = channelRange()
        // (Removed) old grid loop; unified into highlighted loop below
        // Vertical grid + channel tick labels with highlighting
        for ch in stride(from: minCh, through: maxCh, by: step) {
            let x = xForChannel(ch, in: rect)
        
            // Highlight preferred/non-DFS channels to improve readability
            let isHighlight: Bool
            switch band {
            case .twoPointFourGHz:
                isHighlight = [1, 6, 11].contains(ch)
            case .fiveGHz:
                isHighlight = (36...48).contains(ch) || (149...165).contains(ch)
            case .sixGHz:
                isHighlight = false
            }
        
            let lineColor = isHighlight ? Color.primary.opacity(0.35) : Color.secondary.opacity(0.2)
            let lineWidth: CGFloat = isHighlight ? 0.9 : 0.5
        
            var path = Path()
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
        
            // Tick label
            let weight: Font.Weight = isHighlight ? .bold : .regular
            let textColor: Color = isHighlight ? .primary : .secondary
            let label = context.resolve(Text("\(ch)").font(.system(size: 9, weight: weight)).foregroundColor(textColor))
            context.draw(label, at: CGPoint(x: x, y: rect.minY - 6), anchor: .bottom)
        }
        // Baseline
        var base = Path()
        base.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        base.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.stroke(base, with: .color(Color.secondary.opacity(0.3)), lineWidth: 0.8)

        // Left Y-axis with RSSI ticks
        let ticks = [-90, -70, -50, -30]
        for r in ticks {
            let h = heightForRSSI(r, in: rect)
            let y = rect.maxY - h
            var hline = Path()
            hline.move(to: CGPoint(x: rect.minX, y: y))
            hline.addLine(to: CGPoint(x: rect.maxX, y: y))
            context.stroke(hline, with: .color(Color.secondary.opacity(0.15)), lineWidth: 0.5)
            let l = context.resolve(Text("\(r) dBm").font(.system(size: 9)))
            context.draw(l, at: CGPoint(x: rect.minX - 4, y: y), anchor: .trailing)
        }
    }

    private func drawNetworks(context: inout GraphicsContext, rect: CGRect) {
        for n in networks {
            let centerX = xForChannel(n.channel, in: rect)
            let baseW = widthForBandwidth(n.bandwidthMHz, in: rect)
            let h = heightForRSSI(n.rssi, in: rect)
            let isCurrent = (n.bssid == (currentBSSID ?? ""))
            let fill = isCurrent ? Color.blue.opacity(0.25) : colorForSSID(n.ssid).opacity(0.20)
            let stroke = isCurrent ? Color.blue : colorForSSID(n.ssid).opacity(0.8)

            let path = bellPath(centerX: centerX, baseWidth: baseW, height: h, rect: rect)
            context.fill(path, with: .color(fill))
            context.stroke(path, with: .color(stroke), lineWidth: isCurrent ? 2 : 1)

            // Label at the crest
            let crestY = rect.maxY - h - 4
            let labelText = n.ssid ?? "<hidden>"
            let label = context.resolve(Text(labelText).font(.system(size: 10)))
            context.draw(label, at: CGPoint(x: centerX, y: crestY), anchor: .bottom)

            // Channel number below the main label
            let channelLabel = context.resolve(Text("信道 \(n.channel)").font(.system(size: 9)).foregroundColor(.secondary))
            context.draw(channelLabel, at: CGPoint(x: centerX, y: crestY + 12), anchor: .bottom)
        }
    }

    private func bellPath(centerX: CGFloat, baseWidth: CGFloat, height: CGFloat, rect: CGRect) -> Path {
        let leftX = centerX - baseWidth/2
        let rightX = centerX + baseWidth/2
        let baseY = rect.maxY
        let topY = max(rect.minY + 4, baseY - height)
        let cpOffset = max(8, baseWidth * 0.25)
        var path = Path()
        path.move(to: CGPoint(x: leftX, y: baseY))
        // Upward curve to crest
        path.addCurve(
            to: CGPoint(x: centerX, y: topY),
            control1: CGPoint(x: leftX + cpOffset, y: baseY - height * 0.6),
            control2: CGPoint(x: centerX - cpOffset, y: topY)
        )
        // Downward curve to right base
        path.addCurve(
            to: CGPoint(x: rightX, y: baseY),
            control1: CGPoint(x: centerX + cpOffset, y: topY),
            control2: CGPoint(x: rightX - cpOffset, y: baseY - height * 0.6)
        )
        // Close along baseline
        path.addLine(to: CGPoint(x: leftX, y: baseY))
        path.closeSubpath()
        return path
    }

    private func colorForSSID(_ ssid: String?) -> Color {
        // Lightweight deterministic color palette based on SSID hash
        let palette: [Color] = [.green, .orange, .pink, .purple, .mint, .teal]
        let idx: Int
        if let s = ssid, !s.isEmpty {
            idx = abs(s.hashValue) % palette.count
        } else {
            idx = 0
        }
        return palette[idx]
    }
}