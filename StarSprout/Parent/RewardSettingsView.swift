import SwiftUI
import SwiftData

struct RewardSettingsView: View {
    var exit: () -> Void

    @Environment(\.modelContext) private var ctx
    @Query private var settingsList: [AppSettings]
    @State private var newPIN = ""
    @State private var pinSaved = false
    @AppStorage(SoundManager.musicKey) private var musicOn = true
    @AppStorage(SoundManager.sfxKey) private var sfxOn = true

    var body: some View {
        NavigationStack {
            Group {
                if let s = settingsList.first {
                    form(s)
                } else {
                    ProgressView()
                }
            }
            .screenBackground()
            .navigationTitle("奖励设置")
            .toolbar { ParentToolbar(exit: exit) }
        }
    }

    private func form(_ s: AppSettings) -> some View {
        @Bindable var s = s
        return Form {
            Section("每日上限") {
                Stepper("零花钱：\(s.dailyMoneyCap.clean) 元", value: $s.dailyMoneyCap, in: 0...50, step: 1)
                Stepper("屏幕时间：\(Int(s.dailyScreenCap)) 分钟", value: $s.dailyScreenCap, in: 0...120, step: 5)
            }
            Section {
                Picker("全勤奖励", selection: $s.weeklyBonusDays) {
                    Text("一周满 5 天").tag(5)
                    Text("一周满 7 天").tag(7)
                }
                Toggle("破纪录额外 +\(Economy.coinsPerRecord) 金币", isOn: $s.recordBonusEnabled)
                Toggle("第 5 周起提醒我调小单次奖励", isOn: $s.rampDownReminder)
            } header: { Text("激励") } footer: {
                Text("全勤奖励 +\(Economy.coinsWeeklyBonus) 金币。金币由系统固定发放（每次达标 +\(Economy.coinsPerReach)），只能在孩子的星球上使用。")
            }
            Section {
                Toggle("屏幕时间当周有效", isOn: $s.screenTimeWeeklyExpiry)
                Toggle("信任模式（自动确认）", isOn: $s.trustMode)
            } header: { Text("兑现") } footer: {
                Text("App 只记账：零花钱由你线下给，屏幕时间由你在 iPhone「屏幕使用时间」里放行。成绩明显不合理时，即使开了信任模式也会请你核实。")
            }
            Section {
                Toggle("星球背景音乐", isOn: $musicOn)
                Toggle("音效（浇水、施肥、打卡等）", isOn: $sfxOn)
            } header: { Text("声音") } footer: {
                Text("手机静音时不会出声，也不会打断正在播放的其他音乐。")
            }
            Section("提醒") {
                Stepper("晚上 \(s.eveningReminderHour):00 还没运动就提醒", value: $s.eveningReminderHour, in: 17...22)
            }
            Section("孩子") {
                TextField("昵称", text: $s.childName)
                TextField("星球名字", text: $s.planetName)
            }
            Section {
                SecureField("新的 4 位家长密码", text: $newPIN)
                    .keyboardType(.numberPad)
                Button(pinSaved ? "已更新" : "更新密码") {
                    let digits = newPIN.filter(\.isNumber)
                    guard digits.count == 4 else { return }
                    s.parentPIN = digits
                    newPIN = ""
                    pinSaved = true
                }
                .disabled(newPIN.filter(\.isNumber).count != 4)
            } header: { Text("家长密码") }
        }
        .scrollContentBackground(.hidden)
        .onChange(of: s.eveningReminderHour) { _, _ in NotificationManager.reschedule(ctx: ctx) }
        .onChange(of: musicOn) { _, _ in SoundManager.shared.settingsChanged() }
        .onDisappear { try? ctx.save() }
    }
}
