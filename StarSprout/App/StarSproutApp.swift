import SwiftUI
import SwiftData

@main
struct StarSproutApp: App {
    let container: ModelContainer = {
        do {
            if DemoMode.isOn { return try DemoMode.makeContainer() }
            return try ModelContainer(for: Schema(AppSchema.models))
        } catch {
            fatalError("无法创建数据库：\(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.lime)
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Query private var settingsList: [AppSettings]

    var body: some View {
        Group {
            if let screen = DemoMode.screen, screen != .onboarding {
                DemoScreenView(screen: screen)
            } else if let s = settingsList.first, s.consented {
                KidTabView()
            } else {
                OnboardingView()
            }
        }
        .screenBackground()
    }
}
