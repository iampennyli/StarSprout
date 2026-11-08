import Foundation

/// 所有数值集中在这里，方便按测试数据调整
enum Economy {
    static let waterPerDay = 3              // 当天运动一次，水壶装满 3 次
    static let coinsPerReach = 10           // 每次达标
    static let coinsPerRecord = 20          // 破个人纪录
    static let coinsWeeklyBonus = 30        // 周打卡满 N 天
    static let fertilizerCost = 30
    static let fertilizerGrowth = 3
    static let fertilizerCooldownDays = 3
    static let maxPlausibleRopePerMinute: Double = 220

    /// 7 个阶段的累计成长门槛（按每周成长约 18 估算）
    static let stageThresholds = [0, 3, 12, 36, 100, 170, 240]
    static let stageNames = ["种子", "发芽", "小树苗", "小树", "大树", "开花", "结果"]
    static let stageUnlocks = ["给星球和树起名字", "第一张成长照", "星球长出草地", "可以种第一朵花",
                               "小动物来做客", "整颗星球变色", "每周结出星果"]

    /// 1...7
    static func stage(for growth: Int) -> Int {
        var s = 1
        for (i, t) in stageThresholds.enumerated() where growth >= t { s = i + 1 }
        return s
    }

    /// 当前阶段内的进度区间；满级时返回 nil
    static func stageRange(for growth: Int) -> (lower: Int, upper: Int)? {
        let s = stage(for: growth)
        guard s < stageThresholds.count else { return nil }
        return (stageThresholds[s - 1], stageThresholds[s])
    }
}

/// 按距离上次运动的天数决定树的状态。树不会死。
enum TreeMood: Equatable {
    case normal, thirsty, sleepy, hibernating

    static func from(daysSinceExercise days: Int?) -> TreeMood {
        guard let days else { return .normal }
        switch days {
        case ..<3: return .normal
        case 3...4: return .thirsty
        case 5...9: return .sleepy
        default: return .hibernating
        }
    }

    var message: String? {
        switch self {
        case .normal: return nil
        case .thirsty: return "小树有点渴了"
        case .sleepy: return "小树睡着了，运动后浇水叫醒它"
        case .hibernating: return "小树在冬眠，运动后浇一次水就醒"
        }
    }
}
