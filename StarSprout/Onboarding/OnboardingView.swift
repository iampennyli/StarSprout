import SwiftUI
import SwiftData

/// 首次使用：家长填写信息并同意儿童隐私规则 → 建第一个任务
struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx

    @State private var step = 1
    @State private var name = ""
    @State private var ageBand = "9–10 岁"
    @State private var pin = ""
    @State private var consent = false
    @State private var planetName = "星星号"
    @State private var ropeTarget: Double = 150
    @State private var ropeReward: Double = 1

    private let ages = ["6–8 岁", "9–10 岁", "11–12 岁"]

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && pin.filter(\.isNumber).count == 4 && consent
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 6) {
                    Capsule().fill(Theme.lime).frame(height: 4)
                    Capsule().fill(step == 2 ? Theme.lime : Theme.stroke).frame(height: 4)
                }
                if step == 1 { stepOne } else { stepTwo }
            }
            .padding(24)
        }
        .screenBackground()
        .background(alignment: .top) { StarField().frame(height: 240) }
    }

    private var stepOne: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("第 1 步 / 共 2 步 · 请家长填写").font(.footnote).foregroundStyle(Theme.muted)
                Text("先认识一下孩子").font(Theme.titleFont(28))
            }
            field("孩子的昵称", note: "只用来在首页打招呼，不需要真实姓名") {
                TextField("例如：小明", text: $name).textFieldStyle(DarkFieldStyle())
            }
            field("年龄段", note: "用来推荐合适的跳绳和跑步目标") {
                HStack(spacing: 8) {
                    ForEach(ages, id: \.self) { a in
                        Button(a) {
                            ageBand = a
                            ropeTarget = a == "6–8 岁" ? 100 : (a == "9–10 岁" ? 150 : 160)
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(ageBand == a ? Theme.lime : .white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(ageBand == a ? Theme.cardRaised : Theme.card, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ageBand == a ? Theme.lime : Theme.stroke, lineWidth: ageBand == a ? 2 : 1))
                    }
                }
            }
            field("星球名字", note: "孩子的星球叫什么？之后可以改") {
                TextField("星星号", text: $planetName).textFieldStyle(DarkFieldStyle())
            }
            field("家长密码", note: "4 位数字，进入家长模式、确认奖励、分享时使用") {
                SecureField("4 位数字", text: $pin).keyboardType(.numberPad).textFieldStyle(DarkFieldStyle())
            }
            Toggle(isOn: $consent) {
                Text("我是孩子的监护人，已阅读并同意《隐私政策》和《儿童个人信息保护规则》。数据只保存在本机。")
                    .font(.footnote)
            }
            .toggleStyle(.switch)
            Button("下一步：设第一个任务") { step = 2 }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.5)
        }
    }

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("第 2 步 / 共 2 步").font(.footnote).foregroundStyle(Theme.muted)
                Text("设第一个任务").font(Theme.titleFont(28))
                Text("先从跳绳开始，跑步任务可以之后在家长模式里加").font(.footnote).foregroundStyle(Theme.muted)
            }
            VStack(alignment: .leading, spacing: 12) {
                Stepper(value: $ropeTarget, in: 20...300, step: 10) {
                    Text("1 分钟跳 \(Int(ropeTarget)) 个").font(.headline)
                }
                Stepper(value: $ropeReward, in: 0.5...10, step: 0.5) {
                    Text("每次达标 +\(ropeReward.clean) 元零花钱").font(.headline)
                }
                Text("另外：当天运动就有 3 次水浇小树，达标还有 \(Economy.coinsPerReach) 金币")
                    .font(.caption).foregroundStyle(Theme.muted)
            }
            .card()
            HStack(spacing: 10) {
                Button("上一步") { step = 1 }.buttonStyle(OutlineButtonStyle(color: .white, height: 54))
                Button("开始种星球", action: finish).buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func field<Content: View>(_ title: String, note: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.bold())
            content()
            Text(note).font(.caption).foregroundStyle(Theme.muted)
        }
    }

    private func finish() {
        let s = GameEngine.settings(ctx)
        s.childName = name.trimmingCharacters(in: .whitespaces)
        s.ageBand = ageBand
        s.parentPIN = String(pin.filter(\.isNumber).prefix(4))
        s.planetName = planetName.isEmpty ? "星星号" : planetName
        s.createdAt = .now
        _ = GameEngine.tree(ctx)
        if GameEngine.fetch(SportTask.self, ctx).isEmpty {
            ctx.insert(SportTask(kind: .rope, target: ropeTarget, rewardType: .money, rewardAmount: ropeReward))
        }
        s.consented = true
        try? ctx.save()
        Task {
            await NotificationManager.requestAuthorization()
            NotificationManager.reschedule(ctx: ctx)
        }
    }
}

struct DarkFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke))
    }
}
