import SwiftUI

final class UserPreferences: ObservableObject {
    @Published var fontScale: CGFloat

    init() {
        let saved = UserDefaults.standard.double(forKey: "fontScale")
        self.fontScale = saved == 0 ? 1.0 : CGFloat(saved)
    }

    func setFontScale(_ scale: CGFloat) {
        fontScale = scale
        UserDefaults.standard.set(Double(scale), forKey: "fontScale")
    }
}