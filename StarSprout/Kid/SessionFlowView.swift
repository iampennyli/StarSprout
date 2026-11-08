import SwiftUI
import SwiftData

/// 打卡流程：跳绳 = 准备 → 倒数 3 秒 → 计时 1 分钟 → 填个数 → 结果；跑步 = 填公里数 → 结果
struct SessionFlowView: View {
    let task: SportTask
    var onGoPlanet: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    private enum Step { case ready, countdown(Int), running(Int), input, done }

    @State private var step: Step
    @State private var value: Double
    @State private var result: SubmitResult?
    @State private var timerTask: Task<Void, Never>?
    @State private var finishedTick = 0

    init(task: SportTask, onGoPlanet: @escaping () -> Void) {
        self.task = task
        self.onGoPlanet = onGoPlanet
        _step = State(initialValue: task.kind == .rope ? .ready : .input)
        _value = State(initialValue: task.target)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch step {
            case .ready: readyView
            case .countdown(let n): timerView(big: "\(n)", caption: "准备……")
            case .running(let r): timerView(big: String(format: "0:%02d", r), caption: "跳起来！", progress: Double(60 - r) / 60)
            case .input: inputView
            case .done:
                if let result {
                    SuccessView(task: task, result: result,
                                onWater: { onGoPlanet(); dismiss() },
                                onAgain: { self.result = nil; value = task.target; step = task.kind == .rope ? .ready : .input },
                                onHome: { dismiss() })
                }
            }
        }
        .sensoryFeedback(.success, trigger: finishedTick)
        .onDisappear { timerTask?.cancel() }
    }

    // MARK: Header

    private var closeBar: some View {
        HStack {
            Button { timerTask?.cancel(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline).foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.card, in: Circle())
                    .overlay(Circle().stroke(Theme.stroke))
            }
            .accessibilityLabel("关闭")
            Spacer()
            Text("\(task.kind.title) · 目标 \(task.target.clean) \(task.kind.unit)").font(Theme.titleFont(18))
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: Rope timer

    private var readyView: some View {
        VStack(spacing: 24) {
            closeBar
            Spacer()
            Image(systemName: "figure.jumprope")
                .font(.system(size: 90, weight: .bold))
                .foregroundStyle(Theme.lime)
            Text("准备好了吗？").font(Theme.titleFont(28))
            Text("点「开始」后先倒数 3 秒，再计时 1 分钟").foregroundStyle(Theme.muted)
            Spacer()
            VStack(spacing: 12) {
                Button("开始") { startTimer() }.buttonStyle(PrimaryButtonStyle())
                Button("已经跳完了，直接填个数") { step = .input }
                    .font(.subheadline).foregroundStyle(Theme.muted)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func timerView(big: String, caption: String, progress: Double = 0) -> some View {
        VStack(spacing: 20) {
            closeBar
            Spacer()
            ZStack {
                Circle().stroke(Theme.card, lineWidth: 14)
                Circle().trim(from: 0, to: progress)
                    .stroke(Theme.lime, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                VStack(spacing: 4) {
                    Text(big).font(Theme.titleFont(64)).monospacedDigit()
                    Text(caption).foregroundStyle(Theme.muted)
                }
            }
            .frame(width: 230, height: 230)
            .shadow(color: Theme.lime.opacity(0.3), radius: 30)
            Spacer()
            Button("提前结束") { timerTask?.cancel(); step = .input }
                .font(.subheadline).foregroundStyle(Theme.muted)
                .frame(minHeight: 44)
                .padding(.bottom, 24)
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            for n in stride(from: 3, through: 1, by: -1) {
                step = .countdown(n)
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
            for r in stride(from: 60, through: 0, by: -1) {
                step = .running(r)
                if r == 0 { break }
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
            finishedTick += 1
            step = .input
        }
    }

    // MARK: Input

    private var step1: Double { task.kind == .rope ? 1 : 0.1 }
    private var quickPicks: [Double] {
        if task.kind == .rope {
            let t = task.target
            return [t - 30, t - 10, t, t + 10].filter { $0 > 0 }
        }
        return [0.5, 1, 1.5, 2, 3]
    }

    private var inputView: some View {
        VStack(spacing: 18) {
            closeBar
            Spacer()
            Text(task.kind == .rope ? "刚才跳了多少个？" : "今天跑了多少公里？").font(Theme.titleFont(24))
            HStack(spacing: 16) {
                stepButton("minus") { value = max(0, (value - step1).rounded(toPlaces: 1)) }
                    .accessibilityLabel("减少")
                TextField("", value: $value, format: .number.precision(.fractionLength(task.kind == .rope ? 0 : 1)))
                    .keyboardType(task.kind == .rope ? .numberPad : .decimalPad)
                    .multilineTextAlignment(.center)
                    .font(Theme.titleFont(42))
                    .frame(width: 150, height: 76)
                    .background(Theme.bg, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.lime, lineWidth: 2))
                    .accessibilityLabel(task.kind == .rope ? "跳绳个数" : "公里数")
                stepButton("plus") { value = (value + step1).rounded(toPlaces: 1) }
                    .accessibilityLabel("增加")
            }
            Text(task.kind.unit).foregroundStyle(Theme.muted)
            HStack(spacing: 8) {
                ForEach(quickPicks, id: \.self) { v in
                    Button(v.clean) { value = v }
                        .font(.subheadline).foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(Theme.card, in: Capsule())
                        .overlay(Capsule().stroke(Theme.stroke))
                }
            }
            reachHint
            Spacer()
            VStack(spacing: 8) {
                Button("提交") { submit() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(value <= 0)
                Text("没达标也能提交：成绩记下来，水壶照样装满")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var reachHint: some View {
        if value >= task.target {
            Text("达标了！提交后水壶装满，+\(Economy.coinsPerReach) 金币、+\(task.rewardType.format(task.rewardAmount))")
                .font(.subheadline).foregroundStyle(Theme.lime)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.lime))
        } else {
            Text("离目标还差 \((task.target - value).clean) \(task.kind.unit)，提交也能拿到今天的水")
                .font(.subheadline).foregroundStyle(Theme.muted)
                .padding(.horizontal, 14).padding(.vertical, 10)
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.title2.bold()).foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Theme.card, in: Circle())
                .overlay(Circle().stroke(Theme.stroke))
        }
    }

    private func submit() {
        let r = GameEngine.submit(task: task, value: value, ctx: ctx)
        GameEngine.evaluateMedals(ctx: ctx)
        NotificationManager.reschedule(ctx: ctx)
        result = r
        finishedTick += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { step = .done }
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let m = pow(10, Double(places))
        return (self * m).rounded() / m
    }
}

// MARK: - Success

struct SuccessView: View {
    let task: SportTask
    let result: SubmitResult
    var onWater: () -> Void
    var onAgain: () -> Void
    var onHome: () -> Void

    @State private var appeared = false

    private var ci: CheckIn { result.checkIn }

    private var subtitle: String {
        var s = "\(ci.value.clean) \(task.kind.unit)"
        if let last = result.lastValue {
            let diff = ci.value - last
            if diff > 0 { s += "，比上次多 \(diff.clean)" }
            else if diff == 0 { s += "，和上次一样稳" }
        }
        if !ci.reached { s += "，离目标还差 \((task.target - ci.value).clean)" }
        return s
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: ci.reached ? "checkmark" : "figure.wave")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 84, height: 84)
                        .background(ci.reached ? Theme.lime : Theme.cyan, in: Circle())
                        .shadow(color: (ci.reached ? Theme.lime : Theme.cyan).opacity(0.4), radius: 24)
                        .scaleEffect(appeared ? 1 : 0.4)
                    Text(ci.reached ? (ci.isRecord ? "破纪录啦！" : "任务完成！") : "记录好啦！")
                        .font(Theme.titleFont(32))
                    Text(subtitle).foregroundStyle(Theme.muted)
                    if ci.suspicious {
                        Text("这个成绩有点惊人，需要爸爸妈妈核实一下哦")
                            .font(.footnote).foregroundStyle(Theme.gold)
                    }
                }
                .padding(.top, 40)

                if result.recentValues.count > 1 { chart }

                HStack(spacing: 8) {
                    rewardTile(value: result.gotWater ? "水 ×3" : "水壶已满",
                               caption: result.gotWater ? "已到账" : "今天装过了", color: Theme.cyan)
                    rewardTile(value: "+\(result.coins + result.coinsPending)",
                               caption: result.coinsPending > 0 ? "金币 · 部分待确认" : "金币 · 已到账", color: Theme.gold)
                    rewardTile(value: result.realRewardAmount > 0 ? "+" + result.realRewardType.format(result.realRewardAmount) : "—",
                               caption: realCaption, color: Theme.mint)
                }

                if result.weeklyBonus {
                    Text("本周打卡满啦！全勤奖励 +\(Economy.coinsWeeklyBonus) 金币")
                        .font(.subheadline.bold()).foregroundStyle(Theme.gold)
                        .card(padding: 12, radius: 14, border: Theme.gold)
                }

                VStack(spacing: 10) {
                    Button("去给小树浇水", action: onWater).buttonStyle(PrimaryButtonStyle(color: Theme.gold))
                    HStack(spacing: 10) {
                        Button("再来一次", action: onAgain).buttonStyle(OutlineButtonStyle())
                        Button("回到首页", action: onHome).buttonStyle(OutlineButtonStyle(color: .white))
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .onAppear { withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { appeared = true } }
    }

    private var realCaption: String {
        if !ci.reached { return "达标才有" }
        if result.capped { return "今天已到上限" }
        return result.realRewardPending ? "等爸妈确认" : "已到账"
    }

    private var chart: some View {
        let values = result.recentValues
        let maxV = max(values.max() ?? 1, task.target)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("最近 \(values.count) 次").font(.subheadline.bold())
                Spacer()
                Text("目标 \(task.target.clean)").font(.footnote).foregroundStyle(Theme.muted)
            }
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                    let isLast = i == values.count - 1
                    VStack(spacing: 4) {
                        Text(v.clean).font(.caption2.bold()).foregroundStyle(isLast ? Theme.lime : Theme.muted)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isLast ? Theme.lime : Theme.locked)
                            .frame(height: max(8, 90 * v / maxV))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 112, alignment: .bottom)
        }
        .card()
    }

    private func rewardTile(value: String, caption: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(caption).font(.caption2).foregroundStyle(Theme.muted)
        }
        .card(padding: 12, radius: 16)
    }
}
