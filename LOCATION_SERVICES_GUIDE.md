# WiFi Optimizer：启用 Location Services 权限指南

本文指导在 macOS 为 `wifiopt-app` 正确启用 `Location Services`（Core Location），确保应用能显示完整的网络分析 KPI。文档以中文为主，并保留关键技术术语为 English（如 `Info.plist`, `entitlements`, `tccutil`, `bundle id`, `SwiftPM`, `Core Location`）。

## 目标
- 为 `wifiopt-app` 正确启用 `Core Location` 的 When-In-Use 授权。
- 解决在 `SwiftPM`（SPM）构建下 `Info.plist` 未生效导致无授权弹窗的问题。
- 提供一键化脚本与命令参考，便于开发调试。

## 前提条件
- macOS 已启用 `Location Services`。
- 在项目根目录（`WiFi-Optimizer`）运行命令。
- 使用 `swift run wifiopt-app` 启动 SwiftUI 应用（非 CLI）。

## 快速流程
1. 启用系统级 `Location Services`（GUI 与命令）
   - GUI：`System Settings` → `Privacy & Security` → `Location Services` → 开启总开关。
   - 命令快捷打开面板：`open "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"`
   - 提示：若列表暂未出现 `wifiopt-app`，先运行应用触发授权请求后再返回此面板。
2. 校验 `Info.plist` 的使用描述与 `bundle id`
   - 查看 `bundle id`：`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" Sources/wifiopt-app/Info.plist`
   - 检查使用描述键：`/usr/libexec/PlistBuddy -c "Print NSLocationWhenInUseUsageDescription" Sources/wifiopt-app/Info.plist`
   - 若缺失（开发环境可临时添加）：`/usr/libexec/PlistBuddy -c 'Add NSLocationWhenInUseUsageDescription string "Needed to analyze nearby Wi‑Fi networks."' Sources/wifiopt-app/Info.plist`
3. 处理 SPM `Info.plist` 警告，确保构建产物包含该键
   - 验证构建 `.app`：`plutil -p ".build/debug/wifiopt-app.app/Contents/Info.plist" | grep NSLocationWhenInUseUsageDescription || echo "Missing key"`
   - 若缺失，开发模式下为 `.app` 打补丁：`plutil -insert NSLocationWhenInUseUsageDescription -string "Needed to analyze nearby Wi‑Fi networks." ".build/debug/wifiopt-app.app/Contents/Info.plist"`
   - 建议：长期改为 Xcode app target 管理主 `Info.plist`，避免 SPM 下未处理的 `Info.plist`。
4. 重置并重新触发授权弹窗
   - 精确重置：`tccutil reset Location <your.bundle.id>`（使用步骤 2 获取的 `bundle id`）。
   - 备用方案：`tccutil reset Location`（全局重置）。
   - 说明：`tccutil` 仅清理记录，应用仍需在运行时调用 `requestWhenInUseAuthorization`（代码位于 `LocationPermission.swift`）。
5. 启动应用并确认授权生效
   - 启动：`swift run wifiopt-app`（或 `open ".build/debug/wifiopt-app.app"`）。
   - 预期日志：先打印 `Requesting location authorization...`，随后授权状态变为非 0（如 `Location authorization changed to: 3`）。
   - 若无弹窗或状态未变：回到步骤 3 确认构建产物包含使用描述键，并检查 `entitlements` 是否启用位置权限。

## 详细步骤

### 1) 启用系统 Location Services
- 系统设置 → `Privacy & Security` → `Location Services` → 打开。
- 在列表中找到 `wifiopt-app` 并允许访问；若未出现，重新运行应用以触发授权弹窗。

### 2) 检查 `Info.plist` 使用描述
- 文件路径：`Sources/wifiopt-app/Info.plist`
- 必需键：`NSLocationWhenInUseUsageDescription`（推荐描述：`Needed to analyze nearby Wi‑Fi networks.`）

### 3) 检查 `entitlements`（如使用 App Sandbox）
- 文件路径：`Sources/wifiopt-app/wifiopt-app.entitlements`
- 建议包含：
  - `com.apple.security.app-sandbox` = true
  - `com.apple.security.personal-information.location` = true

### 4) 触发授权并确认
- 重置权限记录以确保弹窗出现：
  ```bash
  tccutil reset Location <your.bundle.id>
  ```
- 运行应用并点击允许：
  ```bash
  swift run wifiopt-app
  ```

## 命令参考

- 获取 `bundle id`：
  ```bash
  /usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" Sources/wifiopt-app/Info.plist
  ```

- 验证 `NSLocationWhenInUseUsageDescription` 是否存在：
  ```bash
  /usr/libexec/PlistBuddy -c "Print NSLocationWhenInUseUsageDescription" Sources/wifiopt-app/Info.plist
  ```

- 如缺失则添加（开发环境使用）：
  ```bash
  /usr/libexec/PlistBuddy -c 'Add NSLocationWhenInUseUsageDescription string "Needed to analyze nearby Wi‑Fi networks."' Sources/wifiopt-app/Info.plist
  ```

- 查看 `entitlements`：
  ```bash
  plutil -p Sources/wifiopt-app/wifiopt-app.entitlements
  ```

- 重置 Location 授权（按 app）：
  ```bash
  tccutil reset Location <your.bundle.id>
  ```

- 重置 Location 授权（全局备用）：
  ```bash
  tccutil reset Location
  ```

- 打开系统设置到 Location Services 面板：
  ```bash
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
  ```

- 启动应用以触发弹窗：
  ```bash
  swift run wifiopt-app
  ```

## SPM Info.plist 注意事项（关键）
构建日志提示：
```
warning: 'wifi-optimizer': found 1 file(s) which are unhandled; explicitly declare them as resources or exclude from the target
    /Users/gavinzhang/WiFi-Optimizer/Sources/wifiopt-app/Info.plist
```
这表示在 `SwiftPM` 下，该目标的 `Info.plist` 未自动作为应用的主 `Info.plist` 使用，可能导致 `Core Location` 无授权弹窗。

- 验证构建产物 `.app` 是否包含所需键：
  ```bash
  plutil -p ".build/debug/wifiopt-app.app/Contents/Info.plist" | grep NSLocationWhenInUseUsageDescription || echo "Missing key"
  ```

- 开发模式下的本地补丁（仅用于调试，不用于发布）：
  ```bash
  plutil -insert NSLocationWhenInUseUsageDescription -string "Needed to analyze nearby Wi‑Fi networks." \
    ".build/debug/wifiopt-app.app/Contents/Info.plist"
  ```

- 然后运行应用：
  ```bash
  open ".build/debug/wifiopt-app.app"
  # 或继续使用
  swift run wifiopt-app
  ```

- 备选方案：改用 Xcode app target 管理主 `Info.plist`，获得更稳定的权限行为。

## 验证与预期日志
- 成功时日志示例：
  ```
  Initial location authorization status: 0
  Requesting location authorization...
  Location authorization changed to: 3   # 或任何非 0 的授权状态
  ```
- 网络数据持续采集：
  ```
  Using system profiler data - found 37–45 networks
  ```
- UI：`CurrentNetworkAnalysisView` 显示更完整上下文；`NetworkAnalyzer` 的 KPI（`performanceScore`, `signalQuality`, `interferenceFactors`, `recommendations`, `detailedMetrics`）更准确。

## 常见问题与处理
- 无弹窗、状态一直为 `not determined (0)`：
  - 可能为主 `Info.plist` 未包含 `NSLocationWhenInUseUsageDescription`（SPM 目标未应用该文件）。
  - 按“SPM Info.plist 注意事项”补丁 `.app/Contents/Info.plist` 或改用 Xcode 工程。

- Previously Denied（之前点了“不允许”）：
  - 执行 `tccutil reset Location <bundle id>` 后重新运行应用并允许。

- `entitlements` 未启用：
  - 若使用 `App Sandbox`，确保 `com.apple.security.personal-information.location` 为 true。

- 权限已开启但 UI 无变化：
  - 运行后点击允许，重启应用；检查控制台授权状态是否更新；确认 `ScannerModel` 正在刷新 `networkAnalysis`。

## 自动化脚本（开发便捷）
保存为 `enable_location.sh`：
```bash
#!/usr/bin/env bash
set -euo pipefail
PLIST="Sources/wifiopt-app/Info.plist"
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$PLIST")
/usr/libexec/PlistBuddy -c "Print NSLocationWhenInUseUsageDescription" "$PLIST" >/dev/null 2>&1 || {
  echo "Add NSLocationWhenInUseUsageDescription to $PLIST"; exit 1;
}
echo "Resetting Location consent for $BUNDLE_ID..."
tccutil reset Location "$BUNDLE_ID" || echo "Note: global reset: tccutil reset Location"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
echo "Launching app..."
swift run wifiopt-app
```
运行：
```bash
bash enable_location.sh
```

## 企业/MDM 场景说明
- 在受管设备（supervised）上，可通过 MDM 下发 `Privacy Preferences Policy Control (PPPC)` 配置文件。
- 多数 macOS 版本中，`Core Location` 仍倾向需要用户确认；请依据你的 MDM 能力与 macOS 版本测试。

## 附录：项目中的相关文件
- `Sources/wifiopt-app/LocationPermission.swift`：发起 `CLLocationManager.requestWhenInUseAuthorization` 并记录授权状态日志。
- `Sources/wifiopt-app/Info.plist`：`NSLocationWhenInUseUsageDescription`（SPM 情况下需特别处理）。
- `Sources/wifiopt-app/wifiopt-app.entitlements`：如启用 `App Sandbox`，需包含 `personal-information.location`。
- `Sources/WiFi-Optimizer/SystemProfilerWiFi.swift`：解析 `system_profiler SPAirPortDataType` 到 `NetworkInfo`。
- `Sources/WiFi-Optimizer/NetworkAnalyzer.swift`：KPI（`performanceScore`, `signalQuality`, `interferenceFactors`, `recommendations`, `detailedMetrics`）。
- `Sources/wifiopt-app/CurrentNetworkAnalysisView.swift`：展示当前网络分析与 KPI。