import SwiftUI
import SwiftData

@main
struct StarSproutApp: App {
    let container: ModelContainer = {
        do {
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
            if let s = settingsList.first, s.consented {
                KidTabView()
            } else {
                OnboardingView()
            }
        }
        .screenBackground()
    }
}
