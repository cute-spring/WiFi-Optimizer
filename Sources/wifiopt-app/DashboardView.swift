import SwiftUI
import AppKit
import WiFi_Optimizer

struct DashboardView: View {
    @EnvironmentObject var model: ScannerModel
    @State private var selectedView: ViewSelection = .graph

    enum ViewSelection: String, CaseIterable, Identifiable {
        case graph = "Graph"
        case list = "List"
        var id: Self { self }
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            if selectedView == .graph {
                // Channel occupancy graphs
                TabView {
                    ChannelGraphView(
                        band: .twoPointFourGHz,
                        networks: model.networks.filter { $0.band == .twoPointFourGHz },
                        currentBSSID: model.current?.bssid
                    )
                    .tabItem {
                        Text("2.4 GHz")
                    }
                    ChannelGraphView(
                        band: .fiveGHz,
                        networks: model.networks.filter { $0.band == .fiveGHz },
                        currentBSSID: model.current?.bssid
                    )
                    .tabItem {
                        Text("5 GHz")
                    }
                    ChannelGraphView(
                        band: .sixGHz,
                        networks: model.networks.filter { $0.band == .sixGHz },
                        currentBSSID: model.current?.bssid
                    )
                    .tabItem {
                        Text("6 GHz")
                    }
                    
                    // Current Network Analysis Tab
                    if let analysis = model.networkAnalysis {
                        CurrentNetworkAnalysisView(analysis: analysis)
                            .tabItem {
                                Text("当前网络")
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(model.networks) {
                    TableColumn("SSID") { n in Text(n.ssid ?? "<hidden>") }
                    TableColumn("BSSID") { n in Text(n.bssid).font(.system(.body, design: .monospaced)) }
                    TableColumn("RSSI") { n in Text("\(n.rssi)") }
                    TableColumn("Noise") { n in Text("\(n.noise)") }
                    TableColumn("SNR") { n in Text("\(n.snr)") }
                    TableColumn("Channel") { n in Text("\(n.channel)") }
                    TableColumn("Band") { n in Text(n.band.rawValue) }
                    TableColumn("Width") { n in Text("\(n.bandwidthMHz) MHz") }
                    TableColumn("Security") { n in Text(n.security) }
                }
                .tableStyle(.inset)
            }
        }
        .overlay(alignment: .topTrailing) {
            if Debug.isEnabled() {
                DebugOverlay(
                    interface: model.current,
                    networksCount: model.networks.count,
                    locationStatus: LocationPermission.shared.authorizationStatus
                )
                    .padding([.top, .trailing], 8)
            }
        }
        .padding([.horizontal, .bottom], 16)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Wi‑Fi Environment Scanner").font(.title3).bold()
            Spacer()
            Picker("View", selection: $selectedView) {
                ForEach(ViewSelection.allCases) { selection in
                    Text(selection.rawValue).tag(selection)
                }
            }
            .pickerStyle(.segmented)

            Button(model.isScanning ? "Stop" : "Start") {
                model.isScanning ? model.stop() : model.start()
            }

            if model.current?.ssid == nil {
                Button("打开 Wi‑Fi 设置") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.network?WiFi") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}