import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    @State private var selected: VoltTab = .home

    var body: some View {
        Group {
            switch selected {
            case .home: HomeView(switchTab: { selected = $0 })
            case .workout: WorkoutView()
            case .body: BodyView()
            case .recovery: RecoveryView()
            case .profile: ProfileView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomTabBar(selected: $selected)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewSupport.container)
}
