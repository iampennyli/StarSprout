import SwiftUI

enum Rarity {
    case dust, planet, star, galaxy
    var title: String {
        switch self {
        case .dust: return "星尘级 · 普通"
        case .planet: return "行星级 · 稀有"
        case .star: return "恒星级 · 史诗"
        case .galaxy: return "星系级 · 传奇"
        }
    }
    var color: Color {
        switch self {
        case .dust: return Theme.silver
        case .planet: return Theme.cyan
        case .star: return Theme.gold
        case .galaxy: return Theme.pink
        }
    }
}

/// 勋章判定所需的统计数据
struct MedalStats {
    var activeDays = 0
    var ropeTotal: Double = 0
    var runTotal: Double = 0
    var stage = 1
    var anyReached = false
    var hasRecord = false
    var earlyBird = false
    var weekendFull = false
}

struct MedalDef: Identifiable {
    let id: String
    let name: String
    let glyph: String
    let rarity: Rarity
    let subtitle: String
    let blurb: String
    let hidden: Bool
    let goal: Double
    let unit: String
    let metric: (MedalStats) -> Double

    func earned(_ s: MedalStats) -> Bool { metric(s) >= goal }

    func progress(_ s: MedalStats) -> Double { min(1, metric(s) / goal) }

    func progressText(_ s: MedalStats) -> String {
        if hidden { return "???" }
        if goal <= 1 { return "未解锁" }
        let current = min(metric(s), goal)
        if unit == "天" { return "还差 \(Int(goal - current)) 天" }
        return "\(Int(current).formatted())/\(Int(goal).formatted())\(unit)"
    }
}

enum MedalCatalog {
    private static func days(_ n: Int, _ name: String, _ r: Rarity, _ blurb: String) -> MedalDef {
        MedalDef(id: "days\(n)", name: name, glyph: "\(n)", rarity: r, subtitle: "累计打卡 \(n) 天",
                 blurb: blurb, hidden: false, goal: Double(n), unit: "天", metric: { Double($0.activeDays) })
    }
    private static func rope(_ n: Int, _ glyph: String, _ name: String, _ r: Rarity) -> MedalDef {
        MedalDef(id: "rope\(n)", name: name, glyph: glyph, rarity: r, subtitle: "累计跳绳 \(n.formatted()) 个",
                 blurb: "每一下都算数", hidden: false, goal: Double(n), unit: "", metric: { $0.ropeTotal })
    }
    private static func run(_ n: Int, _ name: String, _ r: Rarity, _ blurb: String) -> MedalDef {
        MedalDef(id: "run\(n)", name: name, glyph: "\(n)", rarity: r, subtitle: "累计跑步 \(n) 公里",
                 blurb: blurb, hidden: false, goal: Double(n), unit: " km", metric: { $0.runTotal })
    }
    private static func stage(_ n: Int, _ glyph: String, _ name: String, _ r: Rarity) -> MedalDef {
        MedalDef(id: "stage\(n)", name: name, glyph: glyph, rarity: r, subtitle: "小树来到第 \(n) 阶段",
                 blurb: Economy.stageUnlocks[n - 1], hidden: false, goal: Double(n), unit: "",
                 metric: { Double($0.stage) })
    }

    static let all: [MedalDef] = [
        days(3, "启航", .dust, "每一颗星星，都从第一步开始"),
        days(7, "一周探险家", .planet, "7 天，飞过了 7 颗小行星"),
        days(14, "星际旅人", .planet, "坚持就是最酷的超能力"),
        days(30, "月球漫步", .star, "一个月的努力，月亮都看见了"),
        days(60, "银河守护", .star, "你已经是星系里的老队员"),
        days(100, "百日星辰", .galaxy, "100 天，闪闪发光"),
        rope(1_000, "1k", "千跳新星", .dust),
        rope(5_000, "5k", "五千跳跃者", .planet),
        rope(10_000, "1万", "万跳达人", .star),
        rope(30_000, "3万", "流星跳手", .star),
        rope(100_000, "10万", "跳绳王者", .galaxy),
        run(10, "起跑线", .dust, "绕 400 米操场 25 圈"),
        run(42, "第一个马拉松", .planet, "跑完了一个全程马拉松的距离"),
        run(100, "百公里旅人", .star, "约 2.4 个马拉松"),
        run(200, "星际长跑家", .galaxy, "近 5 个马拉松"),
        stage(2, "芽", "发芽啦", .dust),
        stage(4, "树", "小树", .planet),
        stage(5, "大树", "长成大树", .star),
        stage(7, "果", "第一颗星果", .galaxy),
        MedalDef(id: "firstReach", name: "第一次达标", glyph: "首", rarity: .dust, subtitle: "第一次完成目标",
                 blurb: "说到做到！", hidden: false, goal: 1, unit: "", metric: { $0.anyReached ? 1 : 0 }),
        MedalDef(id: "record", name: "破纪录", glyph: "破", rarity: .planet, subtitle: "刷新个人最好成绩",
                 blurb: "今天的你，超过了昨天的你", hidden: false, goal: 1, unit: "", metric: { $0.hasRecord ? 1 : 0 }),
        MedalDef(id: "earlyBird", name: "早起的鸟", glyph: "早", rarity: .planet, subtitle: "早上 8 点前运动",
                 blurb: "清晨的星星为你亮着", hidden: true, goal: 1, unit: "", metric: { $0.earlyBird ? 1 : 0 }),
        MedalDef(id: "weekendFull", name: "周末不打烊", glyph: "周", rarity: .planet, subtitle: "周六周日都运动",
                 blurb: "周末也闪闪发光", hidden: true, goal: 1, unit: "", metric: { $0.weekendFull ? 1 : 0 })
    ]

    static func def(_ id: String) -> MedalDef? { all.first { $0.id == id } }
}
