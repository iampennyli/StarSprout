import Foundation
import SwiftData

#if DEBUG
/// 调试开关，只在 Debug 构建里存在（Release / 上架版本完全不包含）。
/// 存在 UserDefaults，App 重启后仍然有效；单元测试的 setUp 会调用 `reset()`。
enum DebugFlags {
    private static let d = UserDefaults.standard

    /// 浇水不消耗水壶，想浇几次浇几次
    static var unlimitedWater: Bool {
        get { d.bool(forKey: "debug.unlimitedWater") }
        set { d.set(newValue, forKey: "debug.unlimitedWater") }
    }

    /// 施肥不花金币、没有冷却
    static var freeFertilizer: Bool {
        get { d.bool(forKey: "debug.freeFertilizer") }
        set { d.set(newValue, forKey: "debug.freeFertilizer") }
    }

    /// 强制小树状态（nil = 按真实打卡记录）
    static var moodOverride: TreeMood? {
        get { d.string(forKey: "debug.mood").flatMap(TreeMood.init(debugKey:)) }
        set { d.set(newValue?.debugKey, forKey: "debug.mood") }
    }

    static func reset() {
        unlimitedWater = false
        freeFertilizer = false
        moodOverride = nil
    }
}

extension TreeMood {
    var debugKey: String {
        switch self {
        case .normal: return "normal"
        case .thirsty: return "thirsty"
        case .sleepy: return "sleepy"
        case .hibernating: return "hibernating"
        }
    }
    init?(debugKey: String) {
        switch debugKey {
        case "normal": self = .normal
        case "thirsty": self = .thirsty
        case "sleepy": self = .sleepy
        case "hibernating": self = .hibernating
        default: return nil
        }
    }
    var debugTitle: String {
        switch self {
        case .normal: return "正常"
        case .thirsty: return "口渴"
        case .sleepy: return "打瞌睡"
        case .hibernating: return "冬眠"
        }
    }
}

/// 调试用的直接操作：跳阶段、加金币等。会写账本（标注「调试」），方便事后分辨。
extension GameEngine {
    /// 把小树直接设到某个阶段的起点
    static func debugSetStage(_ stage: Int, ctx: ModelContext) {
        let s = min(max(stage, 1), Economy.stageThresholds.count)
        tree(ctx).growth = Economy.stageThresholds[s - 1]
        try? ctx.save()
    }

    static func debugAddGrowth(_ n: Int, ctx: ModelContext) {
        let t = tree(ctx)
        t.growth = max(0, t.growth + n)
        try? ctx.save()
    }

    static func debugAddCoins(_ n: Int, ctx: ModelContext) {
        ctx.insert(LedgerEntry(currency: .coins, amount: Double(n), reason: "调试：加金币"))
        try? ctx.save()
    }

    /// 把今天的水壶重新装满
    static func debugRefillWater(ctx: ModelContext, now: Date = .now) {
        let left = waterLeft(fetch(LedgerEntry.self, ctx), now: now)
        let add = Economy.waterPerDay - left
        guard add > 0 else { return }
        ctx.insert(LedgerEntry(currency: .water, amount: Double(add), reason: "调试：装满水壶", date: now))
        try? ctx.save()
    }

    /// 清掉全部装饰（退还金币），方便反复测试商店
    static func debugResetDecorations(ctx: ModelContext) {
        for d in fetch(OwnedDecoration.self, ctx) {
            if let item = d.item {
                ctx.insert(LedgerEntry(currency: .coins, amount: Double(item.price), reason: "调试：退还装饰"))
            }
            ctx.delete(d)
        }
        try? ctx.save()
    }
}
#endif
