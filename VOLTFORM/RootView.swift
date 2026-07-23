import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]

    private var activeProfile: UserProfile? {
        profiles.first(where: { $0.onboardingComplete })
    }

    var body: some View {
        ZStack {
            if activeProfile != nil {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewSupport.container)
}
