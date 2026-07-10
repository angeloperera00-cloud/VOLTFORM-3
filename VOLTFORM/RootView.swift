import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @State private var showSplash = true

    private var activeProfile: UserProfile? {
        profiles.first(where: { $0.onboardingComplete })
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if let profile = activeProfile {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation { showSplash = false }
        }
    }
}
