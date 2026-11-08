import Foundation
import SwiftData

// MARK: - Enums (stored as raw strings in SwiftData models)

enum SportKind: String, Codable, CaseIterable, Identifiable {
    case rope, run
    var id: String { rawValue }
    var title: String { self == .rope ? "跳绳" : "跑步" }
    var unit: String { self == .rope ? "个" : "公里" }
    var symbol: String { self == .rope ? "figure.jumprope" : "figure.run" }
}

enum RewardType: String, Codable, CaseIterable, Identifiable {
    case money, screen
    var id: String { rawValue }
    var title: String { self == .money ? "零花钱" : "屏幕时间" }
    var currency: Currency { self == .money ? .money : .screen }
    func format(_ value: Double) -> String {
        switch self {
        case .money: return "\(value.clean) 元"
        case .screen: return "\(Int(value.rounded())) 分钟"
        }
    }
}

/// 账本里的四种资源。水和金币是虚拟资源，立即到账；零花钱和屏幕时间需要家长确认。
enum Currency: String, Codable {
    case water, coins, money, screen
}

extension Double {
    /// 150.0 -> "150", 1.5 -> "1.5"
    var clean: String {
        rounded() == self ? String(Int(self)) : String(format: "%.1f", self)
    }
}

// MARK: - Models

@Model
final class AppSettings {
    var childName: String = "小明"
    var ageBand: String = "9–10 岁"
    var parentPIN: String = ""
    var consented: Bool = false
    var trustMode: Bool = false
    var dailyMoneyCap: Double = 5
    var dailyScreenCap: Double = 15
    var weeklyBonusDays: Int = 5
    var recordBonusEnabled: Bool = true
    var rampDownReminder: Bool = true
    var screenTimeWeeklyExpiry: Bool = true
    var eveningReminderHour: Int = 20
    var planetName: String = "星星号"
    var praiseText: String = ""
    var praiseDate: Date?
    var createdAt: Date = Date()

    init() {}
}

@Model
final class SportTask {
    var id: UUID = UUID()
    var kindRaw: String = SportKind.rope.rawValue
    /// 跳绳：1 分钟个数；跑步：公里数
    var target: Double = 150
    var rewardTypeRaw: String = RewardType.money.rawValue
    var rewardAmount: Double = 1
    /// Calendar weekday 数字：1=周日 … 7=周六
    var weekdaysRaw: String = "1234567"
    var reminderHour: Int = 18
    var reminderMinute: Int = 30
    var isActive: Bool = true
    var createdAt: Date = Date()

    init(kind: SportKind, target: Double, rewardType: RewardType, rewardAmount: Double,
         weekdays: Set<Int> = Set(1...7), hour: Int = 18, minute: Int = 30) {
        self.kindRaw = kind.rawValue
        self.target = target
        self.rewardTypeRaw = rewardType.rawValue
        self.rewardAmount = rewardAmount
        self.weekdaysRaw = weekdays.sorted().map(String.init).joined()
        self.reminderHour = hour
        self.reminderMinute = minute
    }

    var kind: SportKind {
        get { SportKind(rawValue: kindRaw) ?? .rope }
        set { kindRaw = newValue.rawValue }
    }
    var rewardType: RewardType {
        get { RewardType(rawValue: rewardTypeRaw) ?? .money }
        set { rewardTypeRaw = newValue.rawValue }
    }
    var weekdays: Set<Int> {
        get { Set(weekdaysRaw.compactMap { Int(String($0)) }) }
        set { weekdaysRaw = newValue.sorted().map(String.init).joined() }
    }
    var targetText: String {
        kind == .rope ? "1 分钟跳 \(Int(target)) 个" : "跑 \(target.clean) 公里"
    }
}

@Model
final class CheckIn {
    var id: UUID = UUID()
    var date: Date = Date()
    var taskID: UUID = UUID()
    var kindRaw: String = SportKind.rope.rawValue
    var value: Double = 0
    var target: Double = 0
    var reached: Bool = false
    var isRecord: Bool = false
    /// 成绩明显不合理（如 1 分钟超过 220 个），需要家长核实
    var suspicious: Bool = false
    /// 家长已确认（或信任模式下自动确认）
    var verified: Bool = false
    /// 家长已处理过（确认或驳回）
    var reviewed: Bool = false

    init(taskID: UUID, kind: SportKind, value: Double, target: Double, reached: Bool,
         isRecord: Bool, suspicious: Bool, verified: Bool, date: Date) {
        self.taskID = taskID
        self.kindRaw = kind.rawValue
        self.value = value
        self.target = target
        self.reached = reached
        self.isRecord = isRecord
        self.suspicious = suspicious
        self.verified = verified
        self.reviewed = verified
        self.date = date
    }

    var kind: SportKind { SportKind(rawValue: kindRaw) ?? .rope }
}

/// 账本流水：每一笔水、金币、零花钱、屏幕时间的进出都单独一条
@Model
final class LedgerEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var currencyRaw: String = Currency.coins.rawValue
    var amount: Double = 0
    var reason: String = ""
    var pending: Bool = false
    var checkInID: UUID?

    init(currency: Currency, amount: Double, reason: String, pending: Bool = false,
         checkInID: UUID? = nil, date: Date = Date()) {
        self.currencyRaw = currency.rawValue
        self.amount = amount
        self.reason = reason
        self.pending = pending
        self.checkInID = checkInID
        self.date = date
    }

    var currency: Currency { Currency(rawValue: currencyRaw) ?? .coins }
}

/// 孩子申请提现 / 使用屏幕时间，家长线下兑现后标记完成
@Model
final class RedemptionRequest {
    var id: UUID = UUID()
    var date: Date = Date()
    var currencyRaw: String = Currency.money.rawValue
    var amount: Double = 0
    var done: Bool = false
    var doneAt: Date?

    init(currency: Currency, amount: Double) {
        self.currencyRaw = currency.rawValue
        self.amount = amount
    }

    var currency: Currency { Currency(rawValue: currencyRaw) ?? .money }
}

@Model
final class TreeState {
    var growth: Int = 0
    var lastFertilizedAt: Date?
    /// 很久没运动后回来：下一次浇水成长翻倍
    var comebackPending: Bool = false
    var createdAt: Date = Date()

    init() {}
}

@Model
final class MedalRecord {
    var medalID: String = ""
    var earnedAt: Date = Date()
    var celebrated: Bool = false

    init(medalID: String, earnedAt: Date = Date()) {
        self.medalID = medalID
        self.earnedAt = earnedAt
    }
}

enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        AppSettings.self, SportTask.self, CheckIn.self, LedgerEntry.self,
        RedemptionRequest.self, TreeState.self, MedalRecord.self
    ]
}
