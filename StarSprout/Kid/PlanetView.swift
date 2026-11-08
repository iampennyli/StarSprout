import SwiftUI
import SwiftData

struct PlanetView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.scenePhase) private var scenePhase
    @Query private var trees: [TreeState]
    @Query private var entries: [LedgerEntry]
    @Query private var checkIns: [CheckIn]
    @Query private var settingsList: [AppSettings]
    @Query private var decorations: [OwnedDecoration]
    @State private var showShop = false
    @State private var islandAngle: Double = 0
    @GestureState private var dragAngle: Double = 0
    @State private var floatUp = false
    @AppStorage("didHintIslandDrag") private var didHintDrag = false

    @State private var wiggleTick = 0
    @State private var pulseTick = 0
    @State private var bunnyTick = 0
    @State private var shakeWaterTick = 0
    @State private var shakeFertTick = 0
    @State private var effect: Effect?
    @State private var floatText: String?
    @State private var bubble: String?
    @State private var levelUp: Int?
    @State private var busy = false
    @State private var sway = false

    private enum Effect { case water, fertilizer }

    private var tree: TreeState? { trees.first }
    private var growth: Int { tree?.growth ?? 0 }
    private var stage: Int { Economy.stage(for: growth) }
    private var mood: TreeMood { GameEngine.mood(checkIns) }
    private var water: Int { GameEngine.waterLeft(entries) }
    private var coins: Int { Int(GameEngine.balance(.coins, entries)) }
    private var decor: [DecorSlot: String] { GameEngine.equippedDecorations(decorations) }
    private var fertDaysLeft: Int { tree.map { GameEngine.fertilizerDaysLeft($0) } ?? 0 }

    private let lines = ["嘿！今天运动了吗？", "谢谢你照顾我", "我又长高一点了", "痒痒的，哈哈", "我们一起变强吧"]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            StarField()
            VStack(spacing: 0) {
                header
                scene
                bottomPanel
            }
            if let s = levelUp { levelUpOverlay(stage: s) }
        }
        .sheet(isPresented: $showShop) {
            DecorationShopView(stage: stage, mood: mood)
        }
        .onAppear {
            sway = true
            SoundManager.shared.startMusic()
        }
        .onDisappear { SoundManager.shared.stopMusic() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { SoundManager.shared.startMusic() }
            else { SoundManager.shared.stopMusic(remember: true) }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(settingsList.first?.childName ?? "")的星球").font(Theme.titleFont(30))
                Spacer()
                chip(icon: "drop.fill", text: "\(water)/\(Economy.waterPerDay)", color: Theme.cyan)
                chip(icon: "circle.circle.fill", text: "\(coins)", color: Theme.gold)
            }
            Text(statusLine).font(.footnote).foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var statusLine: String {
        if let m = mood.message { return m }
        let rope = Int(checkIns.filter { $0.kind == .rope && (!$0.suspicious || $0.verified) }.reduce(0) { $0 + $1.value })
        return didHintDrag ? "这棵树陪你跳了 \(rope.formatted()) 个 · 点一点小树试试" : "左右拖动小岛转一转 · 点一点小树试试"
    }

    private func chip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption)
            Text(text).font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10).frame(height: 34)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.stroke))
    }

    // MARK: Scene

    private var scene: some View {
        ZStack(alignment: .bottom) {
            IslandScene(stage: stage, decor: decor, angle: islandAngle + dragAngle, showBunny: stage >= 5) {
                Button(action: tapTree) {
                    TreeView(stage: stage, mood: mood, hat: decor[.hat], ornament: stage >= 3 ? decor[.ornament] : nil)
                        .rotationEffect(.degrees(mood == .normal ? (sway ? 1 : -1) : 0), anchor: .bottom)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: sway)
                        .phaseAnimator([0.0, -5, 4, -2, 0], trigger: wiggleTick) { v, angle in
                            v.rotationEffect(.degrees(angle), anchor: .bottom)
                        } animation: { _ in .easeInOut(duration: 0.16) }
                        .phaseAnimator([1.0, 1.1, 1.0], trigger: pulseTick) { v, s in
                            v.scaleEffect(s, anchor: .bottom)
                        } animation: { _ in .spring(response: 0.3, dampingFraction: 0.45) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("摸摸小树")
            } bunny: {
                Button { bunnyTick += 1; SoundManager.shared.play(.bunny) } label: {
                    BunnyView()
                        .phaseAnimator([0.0, -24, 0], trigger: bunnyTick) { v, y in v.offset(y: y) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("摸摸小兔子")
            }
            // 整座小岛轻轻上下漂浮
            .offset(y: floatUp ? -4 : 4)
            .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: floatUp)

            effectsLayer
        }
        .frame(maxWidth: .infinity)
        .frame(height: 430)
        .clipped()
        .contentShape(Rectangle())
        // 左右拖动小岛转一转
        .gesture(
            DragGesture(minimumDistance: 12)
                .updating($dragAngle) { value, state, _ in state = Double(value.translation.width) / 110 }
                .onEnded { value in
                    islandAngle += Double(value.translation.width) / 110
                    if !didHintDrag { didHintDrag = true }
                }
        )
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.85), value: dragAngle)
        .overlay(alignment: .topLeading) {
            if let bubble {
                Text(bubble)
                    .font(.subheadline.bold()).foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 14, bottomTrailingRadius: 4, topTrailingRadius: 14))
                    .frame(maxWidth: 150, alignment: .leading)
                    .padding(.leading, 20).padding(.top, 40)
                    .transition(.scale(scale: 0.5, anchor: .bottomTrailing).combined(with: .opacity))
            }
        }
        .onAppear { floatUp = true }
    }

    @ViewBuilder
    private var effectsLayer: some View {
        ZStack {
            if effect == .water { WateringEffect() }
            if effect == .fertilizer { FertilizerEffect() }
            if let floatText { FloatingText(text: floatText) }
        }
        .frame(width: 300, height: 300)
        .padding(.bottom, 430 - Island.center.y)
        .allowsHitTesting(false)
    }

    // MARK: Bottom panel

    private var bottomPanel: some View {
        let range = Economy.stageRange(for: growth)
        let progress: Double = range.map { Double(growth - $0.lower) / Double($0.upper - $0.lower) } ?? 1
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(Economy.stageNames[stage - 1]) · 第 \(stage) 阶段 / 共 7 阶段").font(.subheadline.bold())
                    Spacer()
                    Text(range.map { "成长 \(growth) / \($0.upper)" } ?? "已满级").font(.subheadline).foregroundStyle(Theme.muted)
                }
                ProgressBar(value: progress)
                Text(hintText(range: range)).font(.footnote).foregroundStyle(Theme.muted)
            }
            HStack(spacing: 8) {
                actionButton(icon: "drop.fill", title: "浇水", sub: "今日剩 \(water) 次 · +1", tint: Theme.cyan,
                             highlighted: water > 0, shakeTick: shakeWaterTick, action: doWater)
                actionButton(icon: "leaf.fill", title: "施肥",
                             sub: fertDaysLeft > 0 ? "\(fertDaysLeft) 天后可用" : "\(Economy.fertilizerCost) 金币 · +\(Economy.fertilizerGrowth)",
                             tint: Theme.lime, highlighted: false, shakeTick: shakeFertTick, action: doFertilize)
                actionButton(icon: "paintpalette.fill", title: "装饰", sub: "\(coins) 金币可用", tint: Theme.pink,
                             highlighted: false, shakeTick: 0) { showShop = true }
            }
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 14)
        .background(Theme.card, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
        .overlay(alignment: .top) { Rectangle().fill(Theme.stroke).frame(height: 1).padding(.horizontal, 28) }
    }

    private func hintText(range: (lower: Int, upper: Int)?) -> String {
        guard let range else { return "满级啦！每周都会结出星果" }
        let left = range.upper - growth
        let next = Economy.stageNames[stage]
        if water == 0 && !GameEngine.exercisedToday(checkIns) { return "运动后水壶就会装满 · 再长 \(left) 点就到「\(next)」" }
        return "再长 \(left) 点就到「\(next)」：\(Economy.stageUnlocks[stage])"
    }

    private func actionButton(icon: String, title: String, sub: String, tint: Color, highlighted: Bool,
                              shakeTick: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.title3).foregroundStyle(tint)
                Text(title).font(.subheadline.bold()).foregroundStyle(.white)
                Text(sub).font(.caption2).foregroundStyle(tint == Theme.cyan ? Theme.cyan : Theme.gold)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(Theme.bg, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(highlighted ? tint : Theme.stroke, lineWidth: highlighted ? 2 : 1))
        }
        .buttonStyle(.plain)
        .phaseAnimator([0.0, -6, 6, -3, 0], trigger: shakeTick) { v, x in v.offset(x: x) } animation: { _ in .linear(duration: 0.07) }
        .disabled(busy)
    }

    // MARK: Actions

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { bubble = text }
        let current = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if bubble == current { withAnimation { bubble = nil } }
        }
    }

    private func tapTree() {
        guard !busy else { return }
        wiggleTick += 1
        SoundManager.shared.play(.tapTree)
        say(mood.message ?? lines.randomElement()!)
    }

    private func doWater() {
        guard !busy else { return }
        switch GameEngine.water(ctx: ctx) {
        case .noWater:
            shakeWaterTick += 1
            SoundManager.shared.play(.nope)
            say(GameEngine.exercisedToday(checkIns) ? "今天的水用完啦，明天运动后再来" : "运动一次，水壶就会装满哦")
        case .grew(let added, let newStage):
            play(.water, added: added, newStage: newStage)
        default: break
        }
    }

    private func doFertilize() {
        guard !busy else { return }
        switch GameEngine.fertilize(ctx: ctx) {
        case .cooldown(let d):
            shakeFertTick += 1
            SoundManager.shared.play(.nope)
            say("肥料 \(Economy.fertilizerCooldownDays) 天才能用一次，还要等 \(d) 天")
        case .noCoins:
            shakeFertTick += 1
            SoundManager.shared.play(.nope)
            say("金币不够啦，去完成任务吧")
        case .grew(let added, let newStage):
            play(.fertilizer, added: added, newStage: newStage)
        case .noWater: break
        }
    }

    private func play(_ e: Effect, added: Int, newStage: Int?) {
        busy = true
        effect = e
        SoundManager.shared.play(e == .water ? .water : .fertilize)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            pulseTick += 1
            floatText = "+\(added)"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            effect = nil
            floatText = nil
            busy = false
            if let newStage {
                SoundManager.shared.play(.levelup)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { levelUp = newStage }
            }
            GameEngine.evaluateMedals(ctx: ctx)
        }
    }

    // MARK: Level up

    private func levelUpOverlay(stage s: Int) -> some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    RaysView(color: Theme.gold).frame(width: 260, height: 260)
                    Circle().fill(Theme.card).frame(width: 150, height: 150)
                        .overlay(Circle().stroke(Theme.gold, lineWidth: 4))
                    TreeView(stage: s).scaleEffect(0.5).frame(width: 120, height: 130)
                }
                Text("升级啦！").font(Theme.titleFont(36)).foregroundStyle(Theme.gold)
                Text("小树长成了「\(Economy.stageNames[s - 1])」").font(.title3.bold())
                Text("\(Economy.stageUnlocks[s - 1]) · 已存入成长相册").font(.subheadline).foregroundStyle(Theme.muted)
                Button("太棒了") { withAnimation { levelUp = nil } }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(width: 220)
                    .padding(.top, 8)
            }
            .padding(28)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
        .sensoryFeedback(.success, trigger: s)
    }
}

// MARK: - Effects

struct WateringEffect: View {
    @State private var pouring = false
    @State private var falling = false
    var body: some View {
        ZStack {
            Image(systemName: "waterbottle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.cyan)
                .rotationEffect(.degrees(pouring ? -55 : 0))
                .offset(x: pouring ? 70 : 120, y: pouring ? -110 : -150)
                .opacity(pouring ? 1 : 0)
            ForEach(0..<5, id: \.self) { i in
                Capsule().fill(Theme.cyan)
                    .frame(width: 6, height: 11)
                    .offset(x: 40 + CGFloat(i % 3) * 8, y: falling ? -30 : -90)
                    .opacity(falling ? 0 : 1)
                    .animation(.easeIn(duration: 0.5).repeatCount(2, autoreverses: false).delay(0.35 + Double(i) * 0.1), value: falling)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { pouring = true }
            falling = true
        }
    }
}

struct FertilizerEffect: View {
    @State private var go = false
    var body: some View {
        ZStack {
            Circle().stroke(Theme.gold, lineWidth: 6)
                .frame(width: 180, height: 180)
                .scaleEffect(go ? 1.4 : 0.6)
                .opacity(go ? 0 : 0.8)
                .animation(.easeOut(duration: 1).delay(0.5), value: go)
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 20 + CGFloat(i % 2) * 6))
                    .foregroundStyle([Theme.gold, Theme.lime, .white, Theme.pink, Theme.gold][i])
                    .offset(x: [-70, 70, 0, -40, 50][i], y: [-30, -10, -80, 50, 40][i])
                    .scaleEffect(go ? 1.2 : 0)
                    .rotationEffect(.degrees(go ? 90 : 0))
                    .opacity(go ? 0.9 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.55 + Double(i) * 0.08), value: go)
            }
            Image(systemName: "bag.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.lime)
                .rotationEffect(.degrees(go ? -50 : 0))
                .offset(x: 90, y: go ? -120 : -150)
                .opacity(go ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: go)
        }
        .onAppear { go = true }
    }
}

struct FloatingText: View {
    let text: String
    @State private var up = false
    var body: some View {
        Text(text)
            .font(Theme.titleFont(36))
            .foregroundStyle(Theme.lime)
            .offset(y: up ? -120 : -60)
            .opacity(up ? 0 : 1)
            .scaleEffect(up ? 1 : 1.2)
            .onAppear { withAnimation(.easeOut(duration: 0.9)) { up = true } }
    }
}

struct RaysView: View {
    let color: Color
    @State private var spin = false
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Capsule().fill(color.opacity(0.35))
                    .frame(width: 18, height: 130)
                    .offset(y: -65)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
        .rotationEffect(.degrees(spin ? 360 : 0))
        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: spin)
        .onAppear { spin = true }
    }
}
