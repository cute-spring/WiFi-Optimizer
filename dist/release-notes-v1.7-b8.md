# WiFi Optimizer v1.7-b8

Highlights
- Pure white background for Optimization Advice sheet
- Advice cards use pure white with lighter borders and soft shadows
- Cleaner, less gray aesthetic while maintaining readability

Technical
- `OptimizationAdviceView.swift`: switched sheet and cards to `Color.white`
- Packaging reads version from `Sources/wifiopt-app/Info.plist` (`CFBundleShortVersionString=1.7`, `CFBundleVersion=8`)

Known Notes
- Location Services consent reset may not apply per-app. Ensure system Location Services is ON and the app requests authorization when needed.

Assets
- `wifiopt-app_v1.7-b8.zip` contains the macOS `.app` bundle.