import SwiftUI

class AppState: ObservableObject {
    @Published var isDebugPanelVisible: Bool = true
}