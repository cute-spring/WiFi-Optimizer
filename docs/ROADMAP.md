# WiFi Optimizer — Product Roadmap

A pragmatic, prioritized plan to elevate WiFi Optimizer into a professional, high‑value macOS product for users and technicians.

## Vision
Deliver clear, actionable Wi‑Fi insights with professional UX, fast and accurate scanning, robust permissions handling, and shareable reports — all packaged and distributed in a trustworthy way.

## Current Strengths
- SwiftUI desktop app with live scan, channel graphs, and current network analysis.
- Robust scanner that uses CoreWLAN and `system_profiler` with fallback and enrichment logic.
- SNR‑aware channel recommendations per band.
- Debug tooling: `--debug` launcher, overlay, structured logs, Location permission helper.
- CLI tool for headless scanning.
- Packaging script that creates a runnable `.app` and sets `WIFIOPT_DEBUG`.

## Key Gaps
- Location permission is a hard gate for SSID/BSSID; handling and messaging must be first‑class.
- `system_profiler` is heavy; overused in the scan loop.
- SwiftPM warns about unhandled `Info.plist` in target sources.
- Limited tests for parsers, recommender, and matching logic.
- No export/reporting, onboarding, or auto‑update/distribution story.

## Prioritized Improvements

### 1) Permission & Onboarding (User Trust)
- First‑run onboarding that explains why Location permission is required and guides granting it.
- Persistent header status: `Location: …`, `Wi‑Fi: …` with quick actions to open Wi‑Fi and Privacy settings.
- Graceful fallback “Inferred Current Network” when SSID/BSSID are unavailable; clearly labeled as inferred.

### 2) Scanner Performance & Accuracy (Speed + Quality)
- Prefer CoreWLAN for regular ticks; only fall back to `system_profiler` if CoreWLAN results are empty or SSID is gated.
- Configurable scan interval in Settings (`1–10s`), default `3s`.
- Benchmark `wdutil` (Apple recommended) versus `system_profiler` for additional context; integrate selectively if helpful.

### 3) Professional UX Polish (Clarity)
- Channel graphs: clearer current channel highlight, annotate channel widths, show congestion metrics (networks per channel, average SNR).
- “What should I do?” action panel: channel width guidance, DFS warnings, legacy mode advice, concrete router steps.
- Persistent preferences: band filters, interval, theme; store in `UserDefaults`.
- Internationalization (English/Chinese) and consistent terminology.

### 4) Reporting & Export (Shareable Value)
- Export to `CSV/JSON` and one‑page PDF snapshot (summary, graphs, recommendations).
- CLI enhancements: `--json`, `--oneshot`, `--interval`, `--duration`, `--band`, `--output <file>`; avoid infinite loop by default in one‑shot mode.

### 5) Reliability & Tests (Confidence)
- Unit tests: `SystemProfilerWiFi` parser (golden inputs), SSID normalization, BSSID/SSID matching, recommender logic.
- Integration test: synthetic networks fed through scanner, assert analysis output.
- Sample `SPAirPortDataType` fixtures (2.4/5/6 GHz, mixed security, hidden SSIDs).

### 6) Packaging & Distribution (Pro Readiness)
- Fix SwiftPM resource warning by excluding `Sources/wifiopt-app/Info.plist` from target sources.
- Code signing and notarization; build `.dmg` or notarized `.pkg`.
- Auto‑updates via Sparkle; in‑app “Check for updates”.
- Homebrew: cask for app and formula for CLI.

## Feature Ideas That Raise Value
- Co‑channel vs adjacent‑channel interference estimates; overlap visuals for 2.4/5/6 GHz.
- Country code awareness & DFS restrictions; “illegal/risky channel” warnings.
- Multi‑AP detection (mesh/extenders): group by SSID with per‑AP details and channel plan suggestions.
- Best channel plan wizard for home/office scenarios.
- Historical insights: rolling scan history, trends (24h/7d), interference peaks, stability.
- Technician mode: detailed diagnostics bundle, printable reports, configurable verbosity.

## Security & Privacy
- All scanning is local; no data leaves the device by default.
- Privacy page and consent for exporting/sharing reports.
- Avoid storing SSID/BSSID history unless user opts in for trends.

## Developer Ergonomics
- GitHub Actions CI for macOS builds and tests; upload artifacts.
- `swift-format`/`swiftlint` for consistent style.
- Sample data and developer docs for parsers, permission flow, and packaging.

## Concrete Next Steps
1. Onboarding + header status component with quick actions; enable “Inferred Current Network”.
2. Switch to CoreWLAN‑first scanning; make interval configurable.
3. Implement export (`CSV/JSON`) and CLI flags (`--json`, `--oneshot`, `--interval`, `--duration`, `--band`, `--output`).
4. Add unit tests (parser, matching, recommender); introduce fixtures.
5. Fix `Info.plist` resource warning; prepare signing/notarization pipeline.

## Milestones & Timeline
- Phase 1 (Week 1–2): Onboarding + status; CoreWLAN‑first; interval setting.
- Phase 2 (Week 3): Export + CLI enhancements; basic PDF report.
- Phase 3 (Week 4): Tests + fixtures; parser reliability; matching correctness.
- Phase 4 (Week 5): Packaging (sign/notarize), Sparkle auto‑update, Homebrew.
- Phase 5 (Week 6+): Advanced analysis (interference, channel plan wizard), history.

## Acceptance Criteria (Examples)
- App shows `Location: authorized…` and `Wi‑Fi: associated` when permissions are granted and a network is connected.
- Current network analysis appears reliably; when gated, inferred network is labeled and produces recommendations.
- Export outputs correct schema and PDF includes graphs + recommendations.
- CLI one‑shot mode produces `JSON` within `2s` for typical environments.
- Unit tests cover parser edge cases and recommender decisions; CI is green.
- Notarized app installs without warnings; auto‑update works.

## Risks & Mitigations
- SSID/BSSID gating by macOS: invest in onboarding, fallback inference, and clear messaging.
- Variability of system tools: prefer CoreWLAN, keep `system_profiler/wdutil` behind conditionals.
- Distribution friction: follow Apple signing/notarization best practices; provide Homebrew options for CLI.

## Implementation Notes
- Fix SwiftPM resource warning by excluding app `Info.plist` in `Package.swift` target, e.g.:
  ```swift
  .target(
      name: "wifiopt-app",
      path: "Sources/wifiopt-app",
      exclude: ["Info.plist"]
  )
  ```
- Persist settings via `UserDefaults` with sensible defaults. Add a simple `Settings` view.
- PDF snapshot can be generated using `PDFKit` with a lightweight template.
- Use `Sparkle` for updates and GitHub Actions for CI/testing.

—
This roadmap is designed to deliver visible user value quickly while building the technical foundations for a professional, reliable product.