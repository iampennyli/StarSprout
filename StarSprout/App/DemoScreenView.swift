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
        case .trees: TreeGallery()
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

/// 美术检查页：每一行是一个阶段，四列分别是正常 / 口渴 / 打瞌睡 / 冬眠
struct TreeGallery: View {
    private let moods: [TreeMood] = [.normal, .thirsty, .sleepy, .hibernating]
    var body: some View {
        VStack(spacing: 2) {
            ForEach(1...7, id: \.self) { stage in
                HStack(spacing: 2) {
                    Text("\(stage)").font(.caption.bold()).foregroundStyle(Theme.muted).frame(width: 14)
                    ForEach(moods, id: \.self) { mood in
                        ZStack(alignment: .bottom) {
                            PlanetBody(stage: stage, diameter: 150).offset(y: 112)
                            GrassCap(stage: stage).scaleEffect(0.38, anchor: .bottom).padding(.bottom, 26)
                            TreeView(stage: stage, mood: mood).scaleEffect(0.38, anchor: .bottom).padding(.bottom, 32)
                        }
                        .frame(width: 92, height: 106)
                        .clipped()
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(.top, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.bg)
    }
}
