import Foundation

public enum Debug {
    private static let enabled: Bool = {
        return ProcessInfo.processInfo.environment["WIFIOPT_DEBUG"] != nil
    }()

    public static func isEnabled() -> Bool { enabled }

    public static func log(_ message: String) {
        guard enabled else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
        print("[WiFiOpt][\(ts)] \(message)")
    }
}