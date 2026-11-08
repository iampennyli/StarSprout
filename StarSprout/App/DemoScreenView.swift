import SwiftUI
import SwiftData

/// 截图模式下按 -screen 参数直接展示某个页面
struct DemoScreenView: View {
    let screen: DemoScreen
    @Environment(\.modelContext) private var ctx
    @Query(sort: \SportTask.createdAt) private var tasks: [SportTask]
    @State private var success: SubmitResult?

    var body: some View {
        switch screen {
        case .onboarding: OnboardingView()
        case .today: KidTabView(initialTab: .today)
        case .planet: KidTabView(initialTab: .planet)
        case .vault: KidTabView(initialTab: .vault)
        case .parent, .parentTasks, .parentRewards: ParentHomeView(initialTab: parentTab)
        case .pin: PINGateView(title: "进入家长模式") {}
        case .session:
            if let rope = tasks.first(where: { $0.kind == .rope }) {
                SessionFlowView(task: rope) {}
            }
        case .success:
            Group {
                if let rope = tasks.first(where: { $0.kind == .rope }), let success {
                    SuccessView(task: rope, result: success, onWater: {}, onAgain: {}, onHome: {})
                } else {
                    Color.clear
                }
            }
            .onAppear {
                guard success == nil, let rope = tasks.first(where: { $0.kind == .rope }) else { return }
                success = GameEngine.submit(task: rope, value: 176, ctx: ctx)
            }
        case .medal:
            if let r = DemoMode.showcaseMedal(ctx) { MedalUnlockView(record: r) {} }
        case .share:
            if let r = DemoMode.showcaseMedal(ctx), let def = MedalCatalog.def(r.medalID) {
                MedalShareView(def: def, record: r)
            }
        }
    }

    private var parentTab: Int {
        switch screen {
        case .parentTasks: return 1
        case .parentRewards: return 2
        default: return 0
        }
    }
}
