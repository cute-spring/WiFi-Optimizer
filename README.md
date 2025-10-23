# macOS Wi‑Fi Insight & Optimizer

Native Swift/SwiftUI app targeting Apple Silicon to analyze, visualize, and optimize home Wi‑Fi networks.

## Vision & Goals
- Provide real‑time scanning of nearby Wi‑Fi networks with actionable insights.
- Visualize channel occupancy/overlap and guide users to better channels.
- Store local survey data (floor plans, measurements) using SwiftData/Core Data.

## Tech Stack
- Language: Swift
- UI: SwiftUI (macOS target, Universal Binary)
- Core: CoreWLAN for Wi‑Fi scanning
- Visualization: Charts + custom drawing/MapKit/SpriteKit for heatmaps
- Persistence: SwiftData or Core Data (local only)

## Current Status
- Swift package with a core `WiFiScanner` using CoreWLAN
- CLI tool `wifiopt-cli` for continuous scanning and optional band filtering

Run:
```
swift run wifiopt-cli [2.4|5|6]
```

Output columns:
- `SSID`, `BSSID`, `RSSI`, `Noise`, `SNR`, `Channel`, `Band`, `Width`, `Security` (current network marked with `*`)

## Roadmap
1. macOS app scaffold
   - Create SwiftUI macOS app target
   - App sandbox entitlements: com.apple.developer.networking.wifi-info
   - Dashboard list with live updates (Timer/Combine)
2. Channel visualization
   - Charts: 2.4 GHz and 5 GHz occupancy graphs
   - Curve width reflects channel bandwidth (20/40/80/160 MHz)
   - Highlight current network
3. Filtering
   - Band toggles (2.4/5/6 GHz)
   - Search by SSID/BSSID
4. Data persistence
   - Save scans and sessions locally
   - Export CSV/JSON
5. Heatmap
   - Floor plan import
   - Tap‑to‑sample RSSI; interpolate heatmap
6. Recommendations
   - Detect overlap/interference; suggest channels and bandwidths
   - Flag low SNR and roaming issues

## Notes
- CoreWLAN is macOS‑only, link framework in package manifest and app target.
- For security labels, CWNetwork lacks a direct security property; current interface security can be used for the active network.