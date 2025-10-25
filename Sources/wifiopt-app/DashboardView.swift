import SwiftUI
import AppKit
import WiFi_Optimizer
import CoreLocation

struct DashboardView: View {
    @EnvironmentObject var model: ScannerModel
    @EnvironmentObject var location: LocationPermission
    @State private var selectedView: ViewSelection = .graph

    enum ViewSelection: String, CaseIterable, Identifiable {
        case graph = "Graph"
        case list = "List"
        var id: Self { self }
    }

    private var locationText: String {
        switch location.authorizationStatus {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        @unknown default: return "unknown"
        }
    }

    private var locationColor: Color {
        switch location.authorizationStatus {
        case .notDetermined: return .gray
        case .denied: return .red
        case .restricted: return .orange
        case .authorizedWhenInUse: return .blue
        case .authorizedAlways: return .green
        @unknown default: return .gray
        }
    }

    private var associationColor: Color {
        (model.current?.ssid == nil) ? .red : .green
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            if selectedView == .graph {
                // Channel occupancy graphs + current analysis
                TabView {
                    ChannelGraphView(
                        band: .twoPointFourGHz,
                        networks: model.networks.filter { $0.band == .twoPointFourGHz },
                        currentBSSID: model.current?.bssid
                    )
                    .tabItem { Text("2.4 GHz") }

                    ChannelGraphView(
                        band: .fiveGHz,
                        networks: model.networks.filter { $0.band == .fiveGHz },
                        currentBSSID: model.current?.bssid
                    )
                    .tabItem { Text("5 GHz") }

                    ChannelGraphView(
                        band: .sixGHz,
                        networks: model.networks.filter { $0.band == .sixGHz },
                        currentBSSID: model.current?.bssid
                    )
                    .tabItem { Text("6 GHz") }

                    if let analysis = model.networkAnalysis {
                        CurrentNetworkAnalysisView(analysis: analysis)
                            .tabItem { Text("当前网络") }
                    }

                    // New: Quality Reference tab
                    QualityReferenceView()
                        .tabItem { Text("质量参考") }
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
        SectionCard {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Text("Wi‑Fi Environment Scanner")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Picker("View", selection: $selectedView) {
                        ForEach(ViewSelection.allCases) { selection in
                            Text(selection.rawValue).tag(selection)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

                HStack(spacing: 10) {
                    StatusChip("Location: \(locationText)", systemImage: "location", color: locationColor)
                    StatusChip("Wi‑Fi: \(((model.current?.ssid == nil) ? "Not Associated" : "Associated"))", systemImage: "wifi", color: associationColor)

                    if location.authorizationStatus == .denied || location.authorizationStatus == .restricted {
                        Button("Open Privacy Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()


                    HStack(spacing: 8) {
                        Text("Interval")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Stepper("\(Int(model.scanInterval))s", value: $model.scanInterval, in: 1...10, step: 1)
                            .frame(width: 140)
                    }

                    Button(model.isScanning ? "Stop" : "Start") {
                        model.isScanning ? model.stop() : model.start()
                    }
                    .buttonStyle(.borderedProminent)

                    if model.current?.ssid == nil {
                        Button("打开 Wi‑Fi 设置") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.network?WiFi") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}