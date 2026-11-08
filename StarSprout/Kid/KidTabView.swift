import SwiftUI
import SwiftData

enum KidTab: Hashable {
    case today, planet, vault
}

struct KidTabView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \MedalRecord.earnedAt) private var medals: [MedalRecord]

    @State private var tab: KidTab = .today
    @State private var showPIN = false
    @State private var showParent = false
    @State private var celebratedThisSession = false
    @State private var unlocking: MedalRecord?

    var body: some View {
        TabView(selection: $tab) {
            TodayView(tab: $tab, openParent: { showPIN = true }, onSessionClosed: checkUnlock)
                .tabItem { Label("任务", systemImage: "checklist") }
                .tag(KidTab.today)
            PlanetView()
                .tabItem { Label("星球", systemImage: "globe.asia.australia.fill") }
                .tag(KidTab.planet)
            VaultView(openParent: { showPIN = true })
                .tabItem { Label("宝库", systemImage: "shippingbox.fill") }
                .tag(KidTab.vault)
        }
        .toolbarBackground(Theme.nav, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $showPIN) {
            PINGateView(title: "进入家长模式") {
                showPIN = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showParent = true }
            }
        }
        .fullScreenCover(isPresented: $showParent, onDismiss: checkUnlock) {
            ParentHomeView()
        }
        .fullScreenCover(item: $unlocking) { record in
            MedalUnlockView(record: record) {
                record.celebrated = true
                try? ctx.save()
                unlocking = nil
            }
        }
        .onAppear {
            checkUnlock()
            NotificationManager.reschedule(ctx: ctx)
        }
        .onChange(of: tab) { _, _ in checkUnlock() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                celebratedThisSession = false
                checkUnlock()
                NotificationManager.reschedule(ctx: ctx)
            }
        }
    }

    /// 一次打开 App 最多播一场勋章仪式，其余排队到下次
    private func checkUnlock() {
        guard !celebratedThisSession, unlocking == nil, !showParent, !showPIN,
              let next = medals.first(where: { !$0.celebrated }) else { return }
        celebratedThisSession = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { unlocking = next }
    }
}
