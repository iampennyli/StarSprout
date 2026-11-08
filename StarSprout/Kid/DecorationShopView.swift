import SwiftUI
import SwiftData

/// 装饰商店：用金币给星球和小树买装饰。点一件先在上方预览里「试穿」，满意再买。
struct DecorationShopView: View {
    let stage: Int
    let mood: TreeMood

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query private var entries: [LedgerEntry]
    @Query private var owned: [OwnedDecoration]

    @State private var slot: DecorSlot = .hat
    @State private var selected: DecorItem?
    @State private var confirming: DecorItem?
    @State private var celebrate = 0
    @State private var toast: String?

    private var coins: Int { Int(GameEngine.balance(.coins, entries)) }
    private var equipped: [DecorSlot: String] { GameEngine.equippedDecorations(owned) }
    private var ownedIDs: Set<String> { Set(owned.map(\.itemID)) }

    /// 预览 = 已换上的装饰 + 正在试的这件
    private var preview: [DecorSlot: String] {
        var map = equipped
        if let selected { map[selected.slot] = selected.id }
        return map
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            MiniPlanetScene(stage: stage, mood: mood, decor: preview)
                .frame(height: 250)
                .overlay(alignment: .bottom) {
                    if let toast {
                        Text(toast).font(.subheadline.bold()).foregroundStyle(Theme.ink)
                            .padding(.horizontal, 14).frame(height: 34)
                            .background(Theme.lime, in: Capsule())
                            .transition(.scale.combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                }
                .phaseAnimator([1.0, 1.06, 1.0], trigger: celebrate) { v, s in v.scaleEffect(s) }
            slotPicker
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(DecorCatalog.items(in: slot)) { item in
                        itemCard(item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            actionBar
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .confirmationDialog(confirming.map { "花 \($0.price) 金币买「\($0.name)」？" } ?? "",
                            isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }),
                            titleVisibility: .visible) {
            if let item = confirming {
                Button("买下并换上") { buy(item) }
                Button("再想想", role: .cancel) {}
            }
        } message: {
            Text("买了以后永远是你的，可以随时换上或取下")
        }
        .sensoryFeedback(.success, trigger: celebrate)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("装饰星球").font(Theme.titleFont(26))
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "circle.circle.fill").font(.caption)
                Text("\(coins)").font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Theme.gold)
            .padding(.horizontal, 12).frame(height: 34)
            .background(Theme.card, in: Capsule())
            .overlay(Capsule().stroke(Theme.stroke))
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.headline).foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("关闭")
        }
        .padding(.leading, 20).padding(.trailing, 8).padding(.top, 14)
    }

    // MARK: Slots

    private var slotPicker: some View {
        HStack(spacing: 6) {
            ForEach(DecorSlot.allCases) { s in
                Button {
                    withAnimation(.snappy) { slot = s }
                } label: {
                    Text(s.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(slot == s ? Theme.ink : .white)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(slot == s ? Theme.lime : Theme.card, in: Capsule())
                        .overlay(alignment: .topTrailing) {
                            if equipped[s] != nil {
                                Circle().fill(Theme.pink).frame(width: 7, height: 7).offset(x: -6, y: 4)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: Item card

    private func itemCard(_ item: DecorItem) -> some View {
        let isOwned = ownedIDs.contains(item.id)
        let isOn = equipped[item.slot] == item.id
        let locked = !isOwned && stage < item.minStage
        let isSelected = selected?.id == item.id
        let natural = DecorArt.naturalSize(item.id)
        let fit = min(64 / natural.width, 56 / natural.height, 1.4)
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selected = isSelected ? nil : item
            }
            SoundManager.shared.play(.tapTree, volume: 0.5)
        } label: {
            VStack(spacing: 6) {
                DecorArt(id: item.id)
                    .scaleEffect(fit)
                    .frame(width: 70, height: 62)
                    .opacity(locked ? 0.4 : 1)
                    .overlay(alignment: .topTrailing) {
                        if locked {
                            Image(systemName: "lock.fill").font(.caption).foregroundStyle(Theme.muted)
                        }
                    }
                Text(item.name).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(1)
                statusLabel(item, isOwned: isOwned, isOn: isOn, locked: locked)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Theme.lime : (isOn ? Theme.pink : Theme.stroke), lineWidth: isSelected || isOn ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.name)，" + (isOn ? "使用中" : isOwned ? "已拥有" : locked ? "小树第 \(item.minStage) 阶段解锁" : "\(item.price) 金币"))
    }

    @ViewBuilder
    private func statusLabel(_ item: DecorItem, isOwned: Bool, isOn: Bool, locked: Bool) -> some View {
        if isOn {
            Text("使用中").font(.caption.bold()).foregroundStyle(Theme.pink)
        } else if isOwned {
            Text("已拥有").font(.caption).foregroundStyle(Theme.muted)
        } else if locked {
            Text("第 \(item.minStage) 阶段解锁").font(.caption).foregroundStyle(Theme.muted)
        } else {
            HStack(spacing: 3) {
                Image(systemName: "circle.circle.fill").font(.system(size: 10))
                Text("\(item.price)").font(.caption.bold())
            }
            .foregroundStyle(coins >= item.price ? Theme.gold : Theme.dim)
        }
    }

    // MARK: Action bar

    @ViewBuilder
    private var actionBar: some View {
        VStack(spacing: 6) {
            if let item = selected {
                let isOwned = ownedIDs.contains(item.id)
                let isOn = equipped[item.slot] == item.id
                Text(item.blurb).font(.footnote).foregroundStyle(Theme.muted)
                if isOn {
                    Button("取下") {
                        GameEngine.unequipDecoration(item.id, ctx: ctx)
                        SoundManager.shared.play(.coin, volume: 0.6)
                        selected = nil
                    }
                    .buttonStyle(OutlineButtonStyle(color: .white, height: 52))
                } else if isOwned {
                    Button("换上") {
                        GameEngine.equipDecoration(item.id, ctx: ctx)
                        SoundManager.shared.play(.coin)
                        celebrate += 1
                        selected = nil
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.pink, height: 52))
                } else if stage < item.minStage {
                    Button("小树长到第 \(item.minStage) 阶段才能买") {}
                        .buttonStyle(OutlineButtonStyle(color: Theme.muted, height: 52))
                        .disabled(true)
                } else if coins < item.price {
                    Button("还差 \(item.price - coins) 金币 · 去完成任务吧") {
                        SoundManager.shared.play(.nope)
                    }
                    .buttonStyle(OutlineButtonStyle(color: Theme.gold, height: 52))
                } else {
                    Button("购买 · \(item.price) 金币") { confirming = item }
                        .buttonStyle(PrimaryButtonStyle(color: Theme.gold, height: 52))
                }
            } else {
                Text("点一件装饰，先在上面试试看")
                    .font(.subheadline).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
        }
        .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 12)
        .background(Theme.card.ignoresSafeArea(edges: .bottom))
    }

    private func buy(_ item: DecorItem) {
        switch GameEngine.buyDecoration(item.id, ctx: ctx) {
        case .bought:
            SoundManager.shared.play(.fertilize)
            celebrate += 1
            selected = nil
            withAnimation(.spring) { toast = "「\(item.name)」装上啦！" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { withAnimation { toast = nil } }
        case .noCoins, .locked, .alreadyOwned, .unknown:
            SoundManager.shared.play(.nope)
        }
    }
}

/// 不可交互的星球缩略场景，和星球页同样的构图，用于商店预览
struct MiniPlanetScene: View {
    let stage: Int
    let mood: TreeMood
    let decor: [DecorSlot: String]

    var body: some View {
        let ring = PlanetRing.style(for: decor[.ring])
        GeometryReader { geo in
            let scale = min(geo.size.height / 430, geo.size.width / 380)
            ZStack(alignment: .bottom) {
                Circle().fill(Theme.leaf.opacity(0.08)).frame(width: 260, height: 260).padding(.bottom, 150)
                if decor[.sky] == "sky.rainbow" {
                    Rainbow(width: 330).opacity(0.75).padding(.bottom, 150)
                }
                PlanetRing(style: ring, back: true).frame(width: 380, height: 70).padding(.bottom, 26)
                PlanetBody(stage: stage).offset(y: 200)
                PlanetRing(style: ring, back: false).frame(width: 380, height: 70).padding(.bottom, 26)
                GrassCap(stage: stage).padding(.bottom, stage >= 3 ? 122 : 128)
                TreeView(stage: stage, mood: mood, hat: decor[.hat], ornament: stage >= 3 ? decor[.ornament] : nil)
                    .padding(.bottom, 134)
                if let ground = decor[.ground] {
                    DecorArt(id: ground).offset(x: -86).padding(.bottom, 132)
                }
                if stage >= 5 {
                    BunnyView().offset(x: 84).padding(.bottom, 136)
                }
            }
            .frame(width: 380, height: 430)
            .overlay(alignment: .topTrailing) {
                if let sky = decor[.sky], sky != "sky.rainbow" {
                    DecorArt(id: sky).padding(.top, 34).padding(.trailing, 26)
                }
            }
            .clipped()
            .scaleEffect(scale)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(StarField())
        .clipped()
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: decor)
    }
}
