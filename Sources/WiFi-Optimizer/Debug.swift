import Foundation

public enum Debug {
    public static func isEnabled() -> Bool {
        #if WIFIOPT_DEBUG
        return true
        #else
        return false
        #endif
    }

    public static func log(_ message: String) {
        #if WIFIOPT_DEBUG
        let ts = ISO8601DateFormatter().string(from: Date())
        print("[WiFiOpt][\(ts)] \(message)")
        #endif
    }
}