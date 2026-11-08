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
        case .shop: DemoShop()
        case .decor: DecorGallery()
        case .debug:
            #if DEBUG
            DebugPanelView { _ in }
            #else
            EmptyView()
            #endif
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
                        IslandThumbnail(stage: stage, mood: mood, decor: [:])
                        .frame(width: 92, height: 110)
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

private struct DemoShop: View {
    @Query private var trees: [TreeState]
    var body: some View {
        DecorationShopView(stage: Economy.stage(for: trees.first?.growth ?? 0), mood: .normal)
    }
}

/// 美术检查页：上面三种搭配的星球，下面所有装饰的单品图
struct DecorGallery: View {
    private let combos: [[DecorSlot: String]] = [
        [.hat: "hat.crown", .ornament: "ornament.lantern", .ground: "ground.pond", .landmark: "ground.house", .pet: "pet.cat", .sky: "sky.rainbow", .ring: "ring.gold"],
        [.hat: "hat.santa", .ornament: "ornament.lights", .ground: "ground.swing", .landmark: "landmark.windmill", .pet: "pet.penguin", .sky: "sky.balloon", .ring: "ring.ice"],
        [.hat: "hat.bow", .ornament: "ornament.stars", .ground: "ground.flowers", .landmark: "landmark.rocket", .pet: "pet.duck", .sky: "sky.meteor", .ring: "ring.rainbow"],
    ]
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                MiniPlanetScene(stage: 5, mood: .normal, decor: combos[0])
                MiniPlanetScene(stage: 7, mood: .normal, decor: combos[1])
                MiniPlanetScene(stage: 6, mood: .normal, decor: combos[2])
            }
            .frame(height: 150)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                ForEach(DecorCatalog.all) { item in
                    let n = DecorArt.naturalSize(item.id)
                    VStack(spacing: 2) {
                        DecorArt(id: item.id).scaleEffect(min(50 / n.width, 46 / n.height, 1.2)).frame(width: 56, height: 50)
                        Text(item.name).font(.caption2).foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 4)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 54)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.bg)
    }
}
