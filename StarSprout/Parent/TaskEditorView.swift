import SwiftUI
import SwiftData

struct TaskListView: View {
    var exit: () -> Void

    @Environment(\.modelContext) private var ctx
    @Query(sort: \SportTask.createdAt) private var tasks: [SportTask]
    @State private var editing: SportTask?
    @State private var creating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(tasks) { t in
                        Button { editing = t } label: { row(t) }.buttonStyle(.plain)
                    }
                    Button { creating = true } label: {
                        Label("新建任务", systemImage: "plus")
                    }
                    .buttonStyle(OutlineButtonStyle())
                    Text("第一期只有跳绳和跑步两种任务")
                        .font(.caption).foregroundStyle(Theme.muted)
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("任务")
            .toolbar { ParentToolbar(exit: exit) }
            .sheet(item: $editing) { t in TaskEditorView(task: t) }
            .sheet(isPresented: $creating) { TaskEditorView(task: nil) }
        }
    }

    private func row(_ t: SportTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: t.kind.symbol)
                .font(.title3.bold()).foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(t.kind == .rope ? Theme.lime : Theme.cyan, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(t.targetText).font(.subheadline.bold())
                Text("每次达标 +\(t.rewardType.format(t.rewardAmount)) · \(weekdayText(t.weekdays)) · \(String(format: "%02d:%02d", t.reminderHour, t.reminderMinute)) 提醒")
                    .font(.caption).foregroundStyle(Theme.muted)
            }
            Spacer()
            Text(t.isActive ? "进行中" : "已暂停").font(.caption.bold())
                .foregroundStyle(t.isActive ? Theme.lime : Theme.muted)
        }
        .card(padding: 14, radius: 18)
    }
}

func weekdayText(_ days: Set<Int>) -> String {
    if days.count == 7 { return "每天" }
    if days == Set([2, 3, 4, 5, 6]) { return "工作日" }
    if days == Set([1, 7]) { return "周末" }
    let names = [2: "一", 3: "二", 4: "三", 5: "四", 6: "五", 7: "六", 1: "日"]
    return "周" + [2, 3, 4, 5, 6, 7, 1].filter { days.contains($0) }.compactMap { names[$0] }.joined()
}

/// 新建 / 编辑任务：4 步，每一步都有默认值
struct TaskEditorView: View {
    let task: SportTask?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    @State private var kind: SportKind = .rope
    @State private var target: Double = 150
    @State private var rewardType: RewardType = .money
    @State private var amount: Double = 1
    @State private var weekdays: Set<Int> = Set(1...7)
    @State private var time: Date = Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: .now) ?? .now
    @State private var isActive = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    section("① 项目") {
                        Picker("项目", selection: $kind) {
                            ForEach(SportKind.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: kind) { _, k in
                            guard task == nil else { return }
                            target = k == .rope ? 150 : 1
                            rewardType = k == .rope ? .money : .screen
                            amount = k == .rope ? 1 : 5
                        }
                    }
                    section("② 目标") {
                        HStack {
                            Text(kind == .rope ? "1 分钟跳" : "跑")
                            Spacer()
                            Stepper(value: $target, in: kind == .rope ? 20...300 : 0.5...10, step: kind == .rope ? 10 : 0.5) {
                                Text("\(target.clean) \(kind.unit)").font(.title3.bold()).frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        Text(kind == .rope ? "参考：6–8 岁 80–120 个，9–12 岁 120–160 个（可按孩子情况调整）" : "参考：从 1 公里开始，慢慢加")
                            .font(.caption).foregroundStyle(Theme.muted)
                    }
                    section("③ 每次达标奖励") {
                        Picker("奖励类型", selection: $rewardType) {
                            ForEach(RewardType.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { v in
                                Button(rewardType.format(v)) { amount = v }
                                    .font(.subheadline.bold())
                                    .foregroundStyle(amount == v ? Theme.ink : .white)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(amount == v ? (rewardType == .money ? Theme.mint : Theme.cyan) : Theme.bg,
                                                in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.stroke))
                            }
                        }
                        Text("每次达标还会自动得到 \(Economy.coinsPerReach) 金币；当天运动就有水浇小树")
                            .font(.caption).foregroundStyle(Theme.muted)
                    }
                    section("④ 哪几天 · 几点提醒") {
                        HStack(spacing: 6) {
                            ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { d in
                                let on = weekdays.contains(d)
                                Button(["", "日", "一", "二", "三", "四", "五", "六"][d]) {
                                    if on { if weekdays.count > 1 { weekdays.remove(d) } } else { weekdays.insert(d) }
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(on ? Theme.ink : .white)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(on ? Theme.lime : Theme.bg, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.stroke))
                            }
                        }
                        DatePicker("提醒时间", selection: $time, displayedComponents: .hourAndMinute)
                    }
                    if task != nil {
                        Toggle("任务进行中", isOn: $isActive).card(padding: 14, radius: 18)
                    }
                    Button("保存任务", action: save).buttonStyle(PrimaryButtonStyle()).padding(.top, 4)
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle(task == nil ? "新建任务" : "编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { ParentModeBadge() }
            }
            .onAppear(perform: load)
        }
    }

    private var presets: [Double] { rewardType == .money ? [0.5, 1, 2] : [1, 5, 10] }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.footnote).foregroundStyle(Theme.muted)
            content()
        }
        .card(padding: 14, radius: 18)
    }

    private func load() {
        guard let t = task else { return }
        kind = t.kind
        target = t.target
        rewardType = t.rewardType
        amount = t.rewardAmount
        weekdays = t.weekdays
        time = Calendar.current.date(bySettingHour: t.reminderHour, minute: t.reminderMinute, second: 0, of: .now) ?? .now
        isActive = t.isActive
    }

    private func save() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let t = task ?? SportTask(kind: kind, target: target, rewardType: rewardType, rewardAmount: amount)
        t.kind = kind
        t.target = target
        t.rewardType = rewardType
        t.rewardAmount = amount
        t.weekdays = weekdays
        t.reminderHour = comps.hour ?? 18
        t.reminderMinute = comps.minute ?? 30
        t.isActive = isActive
        if task == nil { ctx.insert(t) }
        try? ctx.save()
        NotificationManager.reschedule(ctx: ctx)
        dismiss()
    }
}
