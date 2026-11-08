import Foundation
import SwiftData

/// 演示 / 截图模式：用启动参数打开，数据只放内存，不碰真实数据。
///
///     -demo                 预置一个月左右的演示数据
///     -screen <name>        直接打开某个页面（见 DemoScreen）
///
/// 截图脚本 scripts/screenshots.sh 就是靠这两个参数逐页截图。
enum DemoScreen: String, CaseIterable {
    case onboarding, today, planet, vault, session, success, medal, share
    case parent, parentTasks, parentRewards, pin
    case trees      // 美术检查：7 个阶段 × 4 种状态
    case shop       // 装饰商店
    case decor      // 美术检查：全部装饰 + 几种搭配
}

enum DemoMode {
    static let args = ProcessInfo.processInfo.arguments

    static var isOn: Bool { args.contains("-demo") || screen != nil }

    static var screen: DemoScreen? {
        guard let i = args.firstIndex(of: "-screen"), i + 1 < args.count else { return nil }
        return DemoScreen(rawValue: args[i + 1])
    }

    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(AppSchema.models), configurations: config)
        if screen != .onboarding {
            seed(ModelContext(container))
        }
        return container
    }

    /// 本月大部分日子都有运动，跳绳为主、隔几天跑一次；
    /// 昨天有一条可疑成绩待家长核实，今天跑了步、零花钱待确认，跳绳还没做。
    static func seed(_ ctx: ModelContext) {
        let cal = GameEngine.calendar
        let s = AppSettings()
        s.childName = "小星"
        s.parentPIN = "1234"
        s.consented = true
        s.trustMode = true
        s.praiseText = "这周每天都动起来了，爸爸为你骄傲！"
        s.praiseDate = .now
        ctx.insert(s)

        let rope = SportTask(kind: .rope, target: 150, rewardType: .money, rewardAmount: 1, hour: 18, minute: 30)
        let run = SportTask(kind: .run, target: 2, rewardType: .screen, rewardAmount: 10,
                            weekdays: [1, 4, 7], hour: 9, minute: 0)
        rope.createdAt = cal.date(byAdding: .day, value: -40, to: .now)!
        run.createdAt = cal.date(byAdding: .day, value: -40, to: .now)!
        ctx.insert(rope)
        ctx.insert(run)
        let tree = TreeState()
        ctx.insert(tree)
        try? ctx.save()

        let today = cal.startOfDay(for: .now)
        let ropeValues: [Double] = [128, 136, 141, 150, 147, 153, 158, 149, 155, 162, 160, 151, 166, 158, 170, 163, 168, 172]
        var r = 0
        for back in stride(from: 26, through: 2, by: -1) {
            if back % 7 == 3 || back == 12 { continue }          // 偶尔休息，日历上留空，不标红
            let day = cal.date(byAdding: .day, value: -back, to: today)!
            let evening = cal.date(byAdding: .hour, value: 18, to: day)!
            GameEngine.submit(task: rope, value: ropeValues[r % ropeValues.count], ctx: ctx, now: evening)
            r += 1
            if back % 3 == 0 {
                let morning = cal.date(byAdding: .hour, value: 9, to: day)!
                GameEngine.submit(task: run, value: back % 2 == 0 ? 2.5 : 1.6, ctx: ctx, now: morning)
            }
            let waters = back % 4 == 0 ? 2 : 3
            for _ in 0..<waters { _ = GameEngine.water(ctx: ctx, now: cal.date(byAdding: .hour, value: 20, to: day)!) }
            if back % 5 == 0 { _ = GameEngine.fertilize(ctx: ctx, now: cal.date(byAdding: .hour, value: 21, to: day)!) }
        }

        // 昨天：1 分钟 232 个，超过合理上限，信任模式下也要家长核实
        let yesterday = cal.date(byAdding: .hour, value: 18, to: cal.date(byAdding: .day, value: -1, to: today)!)!
        GameEngine.submit(task: rope, value: 232, ctx: ctx, now: yesterday)
        _ = GameEngine.water(ctx: ctx, now: yesterday)

        // 今天：跑了 2.4 公里，屏幕时间等家长确认
        s.trustMode = false
        GameEngine.submit(task: run, value: 2.4, ctx: ctx, now: cal.date(byAdding: .hour, value: 9, to: today)!)
        _ = GameEngine.water(ctx: ctx, now: cal.date(byAdding: .hour, value: 9, to: today)!)

        ctx.insert(RedemptionRequest(currency: .money, amount: 5))

        // 用攒下的金币买几件装饰
        ctx.insert(LedgerEntry(currency: .coins, amount: 300, reason: "演示金币", date: today))
        for id in ["ground.flowers", "hat.star", "sky.moon", "ornament.lights", "landmark.tent", "pet.duck"] {
            GameEngine.buyDecoration(id, ctx: ctx, now: cal.date(byAdding: .hour, value: 10, to: today)!)
        }

        GameEngine.evaluateMedals(ctx: ctx)
        for m in GameEngine.fetch(MedalRecord.self, ctx) { m.celebrated = true }
        try? ctx.save()
    }

    /// 用于 medal / share 截图：取一枚分量最重的已获得勋章
    static func showcaseMedal(_ ctx: ModelContext) -> MedalRecord? {
        let records = GameEngine.fetch(MedalRecord.self, ctx)
        let order = ["days30", "rope10000", "days14", "rope5000", "days7"]
        for id in order { if let r = records.first(where: { $0.medalID == id }) { return r } }
        return records.last
    }
}
