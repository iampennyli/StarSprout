import SwiftUI
import SwiftData

struct ParentHomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Int

    init(initialTab: Int = 0) {
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $tab) {
            ApprovalsView(exit: { dismiss() })
                .tabItem { Label("审批", systemImage: "checkmark.seal") }
                .tag(0)
            TaskListView(exit: { dismiss() })
                .tabItem { Label("任务", systemImage: "list.bullet") }
                .tag(1)
            RewardSettingsView(exit: { dismiss() })
                .tabItem { Label("奖励", systemImage: "gift") }
                .tag(2)
        }
        .toolbarBackground(Theme.nav, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

/// 家长端统一的导航栏：标题 + 家长模式标识 + 退出
struct ParentToolbar: ToolbarContent {
    var exit: () -> Void
    var body: some ToolbarContent {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) { ParentModeBadge() }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) { ParentModeBadge() }
        }
        #else
        ToolbarItem(placement: .topBarLeading) { ParentModeBadge() }
        #endif
        ToolbarItem(placement: .topBarTrailing) { Button("退出", action: exit) }
    }
}

// MARK: - Approvals & stats

struct ApprovalsView: View {
    var exit: () -> Void

    @Environment(\.modelContext) private var ctx
    @Query(sort: \CheckIn.date, order: .reverse) private var checkIns: [CheckIn]
    @Query private var entries: [LedgerEntry]
    @Query(sort: \RedemptionRequest.date, order: .reverse) private var requests: [RedemptionRequest]
    @Query private var tasks: [SportTask]
    @Query private var trees: [TreeState]
    @Query private var settingsList: [AppSettings]

    private var settings: AppSettings? { settingsList.first }
    private var name: String { settings?.childName ?? "孩子" }
    private var review: [CheckIn] { GameEngine.checkInsNeedingReview(checkIns, entries) }
    private var openRequests: [RedemptionRequest] { requests.filter { !$0.done } }
    private var suggestions: [GoalSuggestion] {
        GameEngine.goalSuggestions(tasks: tasks, checkIns: checkIns, childName: name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    pendingSection
                    statsRow
                    treeCard
                    ForEach(suggestions) { s in suggestionCard(s) }
                    if showRampDown { rampDownCard }
                    weeklyChart
                    praiseRow
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("\(name)的运动")
            .toolbar { ParentToolbar(exit: exit) }
        }
    }

    // 待处理
    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("待处理 \(review.count + openRequests.count)").font(.footnote).foregroundStyle(Theme.muted).padding(.bottom, 4)
            if review.isEmpty && openRequests.isEmpty {
                Text("都处理完啦").font(.subheadline).foregroundStyle(Theme.muted).padding(.vertical, 8)
            }
            ForEach(review) { ci in reviewRow(ci) }
            ForEach(openRequests) { r in requestRow(r) }
        }
        .card(padding: 14, radius: 18)
    }

    private func reviewRow(_ ci: CheckIn) -> some View {
        let pending = entries.filter { $0.checkInID == ci.id && $0.pending }
        let rewards = pending.map { e -> String in
            switch e.currency {
            case .money: return "+\(e.amount.clean) 元"
            case .screen: return "+\(Int(e.amount)) 分钟"
            case .coins: return "+\(Int(e.amount)) 金币（\(e.reason)）"
            case .water: return ""
            }
        }.filter { !$0.isEmpty }.joined(separator: "，")
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(ci.kind.title) \(ci.value.clean) \(ci.kind.unit) · \(ci.reached ? "达标" : "未达标")\(ci.isRecord ? " · 破纪录" : "")")
                        .font(.subheadline.bold())
                    Text(ci.date.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN"))) + (rewards.isEmpty ? "" : " · \(rewards)"))
                        .font(.caption).foregroundStyle(Theme.muted)
                    if ci.suspicious {
                        Text("成绩明显偏高，请核实后再确认").font(.caption.bold()).foregroundStyle(Theme.gold)
                    }
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Button("确认") { GameEngine.approve(ci, ctx: ctx); GameEngine.evaluateMedals(ctx: ctx) }
                    .buttonStyle(PrimaryButtonStyle(height: 38))
                Button("驳回") { GameEngine.reject(ci, ctx: ctx) }
                    .buttonStyle(OutlineButtonStyle(color: Theme.muted, height: 38))
            }
        }
        .padding(.vertical, 10)
    }

    private func requestRow(_ r: RedemptionRequest) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(r.currency == .money ? "申请提现 \(r.amount.clean) 元" : "申请使用屏幕时间 \(Int(r.amount)) 分钟")
                    .font(.subheadline.bold())
                Text(r.currency == .money ? "线下给钱后点「已兑现」" : "在「屏幕使用时间」里放行后点「已兑现」")
                    .font(.caption).foregroundStyle(Theme.muted)
            }
            Spacer()
            Button("已兑现") { GameEngine.completeRedemption(r, ctx: ctx) }
                .font(.subheadline.bold())
                .foregroundStyle(r.currency == .money ? Theme.mint : Theme.cyan)
                .padding(.horizontal, 12).frame(height: 38)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(r.currency == .money ? Theme.mint : Theme.cyan))
        }
        .padding(.vertical, 10)
    }

    private var statsRow: some View {
        let week = GameEngine.activeDaysThisWeek(checkIns)
        let best = checkIns.filter { $0.kind == .rope && (!$0.suspicious || $0.verified) }.map(\.value).max() ?? 0
        let runWeek = checkIns.filter { $0.kind == .run && GameEngine.calendar.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.value }
        return HStack(spacing: 8) {
            statTile("本周打卡", "\(week) / 7 天")
            statTile("跳绳最好", "\(Int(best)) 个")
            statTile("本周跑步", "\(runWeek.clean) km")
        }
    }

    private func statTile(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(t).font(.caption2).foregroundStyle(Theme.muted)
            Text(v).font(.system(size: 18, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .card(padding: 12, radius: 16)
    }

    private var treeCard: some View {
        let growth = trees.first?.growth ?? 0
        let stage = Economy.stage(for: growth)
        let mood = GameEngine.mood(checkIns)
        let water = GameEngine.waterLeft(entries)
        let status: String = {
            if !GameEngine.exercisedToday(checkIns) { return mood.message ?? "今天还没运动" }
            return water > 0 ? "今天运动了，还剩 \(water) 次水没浇" : "今天运动了，水已浇完"
        }()
        return HStack(spacing: 12) {
            Image(systemName: "tree.fill").font(.title2).foregroundStyle(Theme.leaf)
                .frame(width: 40, height: 40).background(Theme.planet, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("星球：\(Economy.stageNames[stage - 1]) · 第 \(stage) 阶段").font(.subheadline.bold())
                Text("\(status) · 金币 \(Int(GameEngine.balance(.coins, entries)))").font(.caption).foregroundStyle(Theme.muted)
            }
        }
        .card(padding: 12, radius: 16)
    }

    private func suggestionCard(_ s: GoalSuggestion) -> some View {
        HStack(spacing: 10) {
            Text(s.text).font(.footnote)
            Spacer(minLength: 0)
            Button(s.raise ? "提高" : "降低") {
                s.task.target = s.newTarget
                try? ctx.save()
            }
            .font(.footnote.bold()).foregroundStyle(Theme.ink)
            .padding(.horizontal, 12).frame(height: 36)
            .background(Theme.lime, in: RoundedRectangle(cornerRadius: 12))
        }
        .card(padding: 12, radius: 16, fill: Theme.cardRaised, border: Theme.lime)
    }

    private var showRampDown: Bool {
        guard let s = settings, s.rampDownReminder else { return false }
        return GameEngine.daysBetween(s.createdAt, .now) >= 28
    }

    private var rampDownCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("已经用了 4 周啦").font(.subheadline.bold())
            Text("可以考虑把每次达标的零花钱或屏幕时间调小一些，让\(name)更多靠养星球来坚持。金币不受影响。")
                .font(.footnote).foregroundStyle(Theme.muted)
        }
        .card(padding: 12, radius: 16, border: Theme.gold)
    }

    private var weeklyChart: some View {
        let rope = checkIns.filter { $0.kind == .rope && (!$0.suspicious || $0.verified) }.prefix(7).reversed()
        let values = rope.map(\.value)
        let maxV = max(values.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 10) {
            Text("跳绳成绩 · 近 \(values.count) 次").font(.subheadline.bold())
            if values.isEmpty {
                Text("还没有跳绳记录").font(.footnote).foregroundStyle(Theme.muted)
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                        VStack(spacing: 4) {
                            Text(v.clean).font(.system(size: 10)).foregroundStyle(Theme.muted)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(i == values.count - 1 ? Theme.lime : Theme.locked)
                                .frame(height: max(6, 80 * v / maxV))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100, alignment: .bottom)
            }
        }
        .card(radius: 18)
    }

    private var praiseRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("给\(name)一句鼓励（会显示在孩子首页）").font(.footnote).foregroundStyle(Theme.muted)
            HStack(spacing: 8) {
                ForEach(["今天真棒！", "又进步了", "明天一起跑"], id: \.self) { t in
                    Button(t) {
                        settings?.praiseText = t
                        settings?.praiseDate = .now
                        try? ctx.save()
                    }
                    .font(.footnote).foregroundStyle(.white)
                    .padding(.horizontal, 12).frame(height: 36)
                    .background(Theme.card, in: Capsule())
                    .overlay(Capsule().stroke(settings?.praiseText == t ? Theme.pink : Theme.stroke))
                }
            }
        }
    }
}
