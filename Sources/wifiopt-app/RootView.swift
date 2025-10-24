import SwiftUI
import CoreLocation

struct RootView: View {
    @EnvironmentObject var model: ScannerModel
    @EnvironmentObject var location: LocationPermission
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    private var needsOnboarding: Bool {
        !hasCompletedOnboarding || location.authorizationStatus == .notDetermined || location.authorizationStatus == .denied || location.authorizationStatus == .restricted
    }

    var body: some View {
        Group {
            if needsOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else {
                DashboardView()
            }
        }
        .environmentObject(model)
        .environmentObject(location)
    }
}