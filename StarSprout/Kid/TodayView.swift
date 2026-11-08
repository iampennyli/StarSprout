import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \SportTask.createdAt) private var tasks: [SportTask]
    @Query private var checkIns: [CheckIn]
    @Query private var entries: [LedgerEntry]
    @Query private var trees: [TreeState]
    @Query private var settingsList: [AppSettings]

    @Binding var tab: KidTab
    var openParent: () -> Void
    var onSessionClosed: () -> Void

    @State private var activeTask: SportTask?

    private var settings: AppSettings? { settingsList.first }
    private var cal: Calendar { GameEngine.calendar }

    private var todayTasks: [SportTask] {
        let wd = cal.component(.weekday, from: .now)
        return tasks.filter { $0.isActive && $0.weekdays.contains(wd) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                balances
                if let praise = praiseLine { praiseBanner(praise) }
                planetCard
                if todayTasks.isEmpty {
                    Text("今天没有安排任务，好好休息～")
                        .foregroundStyle(Theme.muted)
                        .card()
                } else {
                    ForEach(todayTasks) { task in
                        TaskCard(task: task, checkIns: checkIns) { activeTask = task }
                    }
                }
                MonthCalendarView(checkIns: checkIns, weeklyBonusDays: settings?.weeklyBonusDays ?? 5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(alignment: .top) { StarField().frame(height: 220) }
        .screenBackground()
        .fullScreenCover(item: $activeTask, onDismiss: onSessionClosed) { task in
            SessionFlowView(task: task) {
                activeTask = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { tab = .planet }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("探险家\(settings?.childName ?? "") · \(Date.now.formatted(.dateTime.month().day().locale(Locale(identifier: "zh_CN"))))")
                    .font(.footnote).foregroundStyle(Theme.muted)
                Text("今日任务").font(Theme.titleFont(30))
            }
            Spacer()
            Button(action: openParent) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.muted)
                    .frame(width: 44, height: 44)
                    .background(Theme.card, in: Circle())
                    .overlay(Circle().stroke(Theme.stroke))
            }
            .accessibilityLabel("进入家长模式")
        }
    }

    private var balances: some View {
        Button { tab = .vault } label: {
            HStack(spacing: 8) {
                BalanceChip(title: "零花钱", value: "¥\(GameEngine.balance(.money, entries).clean)", color: Theme.mint)
                BalanceChip(title: "屏幕时间", value: "\(Int(GameEngine.balance(.screen, entries, settings: settings))) 分", color: Theme.cyan)
                BalanceChip(title: "金币", value: "\(Int(GameEngine.balance(.coins, entries)))", color: Theme.gold)
            }
        }
        .buttonStyle(.plain)
    }

    private var praiseLine: String? {
        guard let s = settings, !s.praiseText.isEmpty, let d = s.praiseDate,
              cal.isDateInToday(d) else { return nil }
        return s.praiseText
    }

    private func praiseBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.fill").foregroundStyle(Theme.pink)
            Text("爸爸妈妈说：\(text)").font(.subheadline.weight(.semibold))
        }
        .card(padding: 12, radius: 16, fill: Theme.cardRaised, border: Theme.pink.opacity(0.6))
    }

    private var planetCard: some View {
        let tree = trees.first
        let growth = tree?.growth ?? 0
        let stage = Economy.stage(for: growth)
        let water = GameEngine.waterLeft(entries)
        let mood = GameEngine.mood(checkIns)
        let hint: String = {
            if water > 0 { return "今天的水壶里还有 \(water) 次水，去浇吧" }
            if GameEngine.exercisedToday(checkIns) { return "今天的水浇完啦，明天运动后再来" }
            return mood.message ?? "运动后水壶就会装满"
        }()
        return Button { tab = .planet } label: {
            HStack(spacing: 12) {
                ZStack(alignment: .bottom) {
                    Circle().fill(Theme.planet).frame(width: 64, height: 64).offset(y: 22)
                    TreeView(stage: stage, mood: mood).scaleEffect(0.24).frame(width: 58, height: 62)
                }
                .frame(width: 72, height: 72)
                .clipped()
                VStack(alignment: .leading, spacing: 4) {
                    Text("我的星球 · \(Economy.stageNames[stage - 1])").font(.headline)
                    Text(hint).font(.footnote).foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
                Text("去照顾")
                    .font(.subheadline.bold()).foregroundStyle(water > 0 ? Theme.cyan : Theme.gold)
                    .padding(.horizontal, 12).frame(height: 36)
                    .overlay(Capsule().stroke(water > 0 ? Theme.cyan : Theme.gold, lineWidth: 2))
            }
            .card(padding: 12, radius: 22)
        }
        .buttonStyle(.plain)
    }
}

struct TaskCard: View {
    let task: SportTask
    let checkIns: [CheckIn]
    var start: () -> Void

    private var reachedToday: Int {
        checkIns.filter { $0.taskID == task.id && $0.reached && GameEngine.calendar.isDateInToday($0.date) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: task.kind.symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 52, height: 52)
                    .background(task.kind == .rope ? Theme.lime : Theme.cyan, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.kind.title).font(Theme.titleFont(22))
                    Text(reachedToday > 0 ? "\(task.targetText) · 今天已达标 \(reachedToday) 次" : task.targetText)
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
            }
            HStack(spacing: 8) {
                RewardPill(text: "水 ×3", color: Theme.cyan)
                RewardPill(text: "+\(Economy.coinsPerReach) 金币", color: Theme.gold)
                RewardPill(text: "+" + task.rewardType.format(task.rewardAmount), color: Theme.mint)
            }
            Button(task.kind == .rope ? "开始" : "跑完了，打卡", action: start)
                .buttonStyle(PrimaryButtonStyle(color: task.kind == .rope ? Theme.lime : Theme.cyan, height: 50))
        }
        .card(radius: 22)
    }
}
