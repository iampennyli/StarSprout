import SwiftUI
import SwiftData

#if DEBUG
/// 调试面板（只在 Debug 构建里有）：放开星球成长，方便测试各阶段的样子、装饰、动画和状态。
/// 入口：星球页标题右侧的小瓢虫按钮。
struct DebugPanelView: View {
    /// 跳到更高阶段后，回到星球页播放升级动画
    var onLevelUp: (Int) -> Void

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query private var trees: [TreeState]
    @Query private var entries: [LedgerEntry]

    @State private var unlimitedWater = DebugFlags.unlimitedWater
    @State private var freeFertilizer = DebugFlags.freeFertilizer
    @State private var mood: String = DebugFlags.moodOverride?.debugKey ?? "auto"
    @State private var playLevelUp = true

    private var growth: Int { trees.first?.growth ?? 0 }
    private var stage: Int { Economy.stage(for: growth) }
    private var coins: Int { Int(GameEngine.balance(.coins, entries)) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("当前", value: "第 \(stage) 阶段「\(Economy.stageNames[stage - 1])」· 成长 \(growth)")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(1...7, id: \.self) { s in
                            Button {
                                jump(to: s)
                            } label: {
                                VStack(spacing: 2) {
                                    Text("\(s)").font(.headline)
                                    Text(Economy.stageNames[s - 1]).font(.caption2)
                                }
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .foregroundStyle(s == stage ? Theme.ink : .white)
                                .background(s == stage ? Theme.lime : Theme.cardRaised, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    HStack {
                        Button("成长 −10") { GameEngine.debugAddGrowth(-10, ctx: ctx) }
                        Spacer()
                        Button("+1") { grow(1) }
                        Spacer()
                        Button("+10") { grow(10) }
                    }
                    .buttonStyle(.bordered)
                    Toggle("跳到更高阶段时播放升级动画", isOn: $playLevelUp)
                } header: { Text("成长阶段") }

                Section {
                    Toggle("不限次浇水（不消耗水壶）", isOn: $unlimitedWater)
                        .onChange(of: unlimitedWater) { _, v in DebugFlags.unlimitedWater = v }
                    Toggle("免费施肥（不花金币、无冷却）", isOn: $freeFertilizer)
                        .onChange(of: freeFertilizer) { _, v in DebugFlags.freeFertilizer = v }
                    Button("把今天的水壶装满") { GameEngine.debugRefillWater(ctx: ctx) }
                } header: { Text("浇水施肥") }

                Section {
                    LabeledContent("金币", value: "\(coins)")
                    HStack {
                        Button("+100") { GameEngine.debugAddCoins(100, ctx: ctx) }
                        Spacer()
                        Button("+500") { GameEngine.debugAddCoins(500, ctx: ctx) }
                        Spacer()
                        Button("+2000") { GameEngine.debugAddCoins(2000, ctx: ctx) }
                    }
                    .buttonStyle(.bordered)
                    Button("清空全部装饰（退还金币）", role: .destructive) { GameEngine.debugResetDecorations(ctx: ctx) }
                } header: { Text("金币与装饰") }

                Section {
                    Picker("小树状态", selection: $mood) {
                        Text("跟随打卡").tag("auto")
                        ForEach([TreeMood.normal, .thirsty, .sleepy, .hibernating], id: \.debugKey) { m in
                            Text(m.debugTitle).tag(m.debugKey)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: mood) { _, v in DebugFlags.moodOverride = TreeMood(debugKey: v) }
                } header: { Text("小树状态") } footer: {
                    Text("这些开关只存在于 Debug 构建，正式版本不包含。开关会一直保留，测完记得关掉。")
                }

                Section {
                    Button("关闭全部调试开关") {
                        DebugFlags.reset()
                        unlimitedWater = false
                        freeFertilizer = false
                        mood = "auto"
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("调试 · 星球")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } }
            }
        }
    }

    private func jump(to s: Int) {
        let before = stage
        GameEngine.debugSetStage(s, ctx: ctx)
        GameEngine.evaluateMedals(ctx: ctx)
        if s > before && playLevelUp {
            dismiss()
            onLevelUp(s)
        }
    }

    private func grow(_ n: Int) {
        let before = stage
        GameEngine.debugAddGrowth(n, ctx: ctx)
        GameEngine.evaluateMedals(ctx: ctx)
        if stage > before && playLevelUp {
            dismiss()
            onLevelUp(stage)
        }
    }
}
#endif
