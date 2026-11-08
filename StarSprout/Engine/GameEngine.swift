import Foundation
import SwiftData

struct SubmitResult {
    let checkIn: CheckIn
    let previousBest: Double?
    let lastValue: Double?
    let gotWater: Bool
    let coins: Int
    let coinsPending: Int
    let realRewardType: RewardType
    let realRewardAmount: Double
    let realRewardPending: Bool
    let capped: Bool
    let weeklyBonus: Bool
    let recentValues: [Double]
}

enum TreeActionResult: Equatable {
    case grew(added: Int, newStage: Int?)
    case noWater
    case cooldown(daysLeft: Int)
    case noCoins
}

struct GoalSuggestion: Identifiable {
    let id = UUID()
    let task: SportTask
    let newTarget: Double
    let raise: Bool
    let text: String
}

/// 所有奖励与养成规则。界面只调用这里，不自己算账。
enum GameEngine {

    /// 周一开头的公历
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.locale = Locale(identifier: "zh_CN")
        return c
    }()

    // MARK: - Fetch helpers

    static func fetch<T: PersistentModel>(_ type: T.Type, _ ctx: ModelContext) -> [T] {
        (try? ctx.fetch(FetchDescriptor<T>())) ?? []
    }

    static func settings(_ ctx: ModelContext) -> AppSettings {
        if let s = fetch(AppSettings.self, ctx).first { return s }
        let s = AppSettings()
        ctx.insert(s)
        return s
    }

    static func tree(_ ctx: ModelContext) -> TreeState {
        if let t = fetch(TreeState.self, ctx).first { return t }
        let t = TreeState()
        ctx.insert(t)
        return t
    }

    // MARK: - Dates

    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: a), to: calendar.startOfDay(for: b)).day ?? 0
    }

    static func weekKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(c.yearForWeekOfYear ?? 0)-\(c.weekOfYear ?? 0)"
    }

    static func activeDaysThisWeek(_ checkIns: [CheckIn], now: Date = .now) -> Int {
        Set(checkIns
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
            .map { calendar.startOfDay(for: $0.date) }).count
    }

    // MARK: - Balances

    /// 已到账余额（不含待确认）。水只算今天；屏幕时间可设为当周有效。
    static func balance(_ currency: Currency, _ entries: [LedgerEntry], settings: AppSettings? = nil, now: Date = .now) -> Double {
        entries.filter { e in
            guard e.currencyRaw == currency.rawValue, !e.pending else { return false }
            switch currency {
            case .water:
                return calendar.isDate(e.date, inSameDayAs: now)
            case .screen:
                if settings?.screenTimeWeeklyExpiry ?? true {
                    return calendar.isDate(e.date, equalTo: now, toGranularity: .weekOfYear)
                }
                return true
            case .coins, .money:
                return true
            }
        }
        .reduce(0) { $0 + $1.amount }
    }

    static func pendingAmount(_ currency: Currency, _ entries: [LedgerEntry]) -> Double {
        entries.filter { $0.currencyRaw == currency.rawValue && $0.pending }.reduce(0) { $0 + $1.amount }
    }

    static func waterLeft(_ entries: [LedgerEntry], now: Date = .now) -> Int {
        max(0, Int(balance(.water, entries, now: now)))
    }

    static func exercisedToday(_ checkIns: [CheckIn], now: Date = .now) -> Bool {
        checkIns.contains { calendar.isDate($0.date, inSameDayAs: now) }
    }

    // MARK: - Tree mood

    static func mood(_ checkIns: [CheckIn], now: Date = .now) -> TreeMood {
        guard let last = checkIns.map(\.date).max() else { return .normal }
        return TreeMood.from(daysSinceExercise: daysBetween(last, now))
    }

    static func fertilizerDaysLeft(_ tree: TreeState, now: Date = .now) -> Int {
        guard let last = tree.lastFertilizedAt else { return 0 }
        return max(0, Economy.fertilizerCooldownDays - daysBetween(last, now))
    }

    // MARK: - Submit a check-in

    @discardableResult
    static func submit(task: SportTask, value: Double, ctx: ModelContext, now: Date = .now) -> SubmitResult {
        let s = settings(ctx)
        let tree = tree(ctx)
        let allCheckIns = fetch(CheckIn.self, ctx)
        let entries = fetch(LedgerEntry.self, ctx)
        let sameKind = allCheckIns.filter { $0.kindRaw == task.kindRaw }.sorted { $0.date < $1.date }

        let moodBefore = mood(allCheckIns, now: now)
        let previousBest = sameKind.filter { !$0.suspicious || $0.verified }.map(\.value).max()
        let lastValue = sameKind.last?.value
        let reached = value >= task.target
        let suspicious = task.kind == .rope && value > Economy.maxPlausibleRopePerMinute
        let isRecord = task.kind == .rope && previousBest != nil && value > (previousBest ?? .infinity)
        let needsParent = !s.trustMode || suspicious

        let ci = CheckIn(taskID: task.id, kind: task.kind, value: value, target: task.target,
                         reached: reached, isRecord: isRecord, suspicious: suspicious,
                         verified: !needsParent, date: now)
        ctx.insert(ci)

        // 1. 水：当天第一次运动（不论是否达标）装满水壶
        let hadWaterToday = entries.contains {
            $0.currencyRaw == Currency.water.rawValue && $0.amount > 0 && calendar.isDate($0.date, inSameDayAs: now)
        }
        if !hadWaterToday {
            ctx.insert(LedgerEntry(currency: .water, amount: Double(Economy.waterPerDay),
                                   reason: "今天运动了，水壶装满", date: now))
            if moodBefore != .normal { tree.comebackPending = true }
        }

        // 2. 金币：达标立即到账（成绩可疑时待核实）；破纪录需家长确认
        var coins = 0, coinsPending = 0
        if reached {
            ctx.insert(LedgerEntry(currency: .coins, amount: Double(Economy.coinsPerReach),
                                   reason: "\(task.kind.title)达标", pending: suspicious, checkInID: ci.id, date: now))
            if suspicious { coinsPending += Economy.coinsPerReach } else { coins += Economy.coinsPerReach }
        }
        if isRecord && s.recordBonusEnabled {
            ctx.insert(LedgerEntry(currency: .coins, amount: Double(Economy.coinsPerRecord),
                                   reason: "破纪录", pending: needsParent, checkInID: ci.id, date: now))
            if needsParent { coinsPending += Economy.coinsPerRecord } else { coins += Economy.coinsPerRecord }
        }

        // 3. 真实奖励：达标才给，受每日上限约束，默认等家长确认
        var realAmount = 0.0
        var capped = false
        if reached {
            let type = task.rewardType
            let cap = type == .money ? s.dailyMoneyCap : s.dailyScreenCap
            let usedToday = entries.filter {
                $0.currencyRaw == type.currency.rawValue && $0.amount > 0 && $0.checkInID != nil
                    && calendar.isDate($0.date, inSameDayAs: now)
            }.reduce(0) { $0 + $1.amount }
            realAmount = min(task.rewardAmount, max(0, cap - usedToday))
            if realAmount > 0 {
                ctx.insert(LedgerEntry(currency: type.currency, amount: realAmount,
                                       reason: "\(task.kind.title)达标奖励", pending: needsParent,
                                       checkInID: ci.id, date: now))
            } else {
                capped = true
            }
        }

        // 4. 周全勤
        let weekly = grantWeeklyBonusIfNeeded(ctx: ctx, checkIns: allCheckIns + [ci], entries: entries,
                                              settings: s, now: now)
        try? ctx.save()

        // 待核实的可疑成绩不进“最近 5 次”图表，免得和“破纪录”自相矛盾
        let trusted = sameKind.filter { !$0.suspicious || $0.verified }.map(\.value)
        let recent = Array((trusted + [value]).suffix(5))
        return SubmitResult(checkIn: ci, previousBest: previousBest, lastValue: lastValue,
                            gotWater: !hadWaterToday, coins: coins, coinsPending: coinsPending,
                            realRewardType: task.rewardType, realRewardAmount: realAmount,
                            realRewardPending: needsParent, capped: capped, weeklyBonus: weekly,
                            recentValues: recent)
    }

    @discardableResult
    static func grantWeeklyBonusIfNeeded(ctx: ModelContext, checkIns: [CheckIn], entries: [LedgerEntry],
                                         settings: AppSettings, now: Date) -> Bool {
        let key = "全勤奖励 " + weekKey(now)
        guard !entries.contains(where: { $0.reason == key }) else { return false }
        guard activeDaysThisWeek(checkIns, now: now) >= settings.weeklyBonusDays else { return false }
        ctx.insert(LedgerEntry(currency: .coins, amount: Double(Economy.coinsWeeklyBonus), reason: key, date: now))
        return true
    }

    // MARK: - Tree actions

    static func water(ctx: ModelContext, now: Date = .now) -> TreeActionResult {
        let entries = fetch(LedgerEntry.self, ctx)
        guard waterLeft(entries, now: now) >= 1 else { return .noWater }
        let t = tree(ctx)
        let before = Economy.stage(for: t.growth)
        let add = t.comebackPending ? 2 : 1
        t.comebackPending = false
        ctx.insert(LedgerEntry(currency: .water, amount: -1,
                               reason: add == 2 ? "浇水（回归礼，成长翻倍）" : "浇水", date: now))
        t.growth += add
        let after = Economy.stage(for: t.growth)
        try? ctx.save()
        return .grew(added: add, newStage: after > before ? after : nil)
    }

    static func fertilize(ctx: ModelContext, now: Date = .now) -> TreeActionResult {
        let t = tree(ctx)
        let left = fertilizerDaysLeft(t, now: now)
        if left > 0 { return .cooldown(daysLeft: left) }
        let entries = fetch(LedgerEntry.self, ctx)
        guard balance(.coins, entries) >= Double(Economy.fertilizerCost) else { return .noCoins }
        let before = Economy.stage(for: t.growth)
        ctx.insert(LedgerEntry(currency: .coins, amount: -Double(Economy.fertilizerCost), reason: "施肥", date: now))
        t.growth += Economy.fertilizerGrowth
        t.lastFertilizedAt = now
        let after = Economy.stage(for: t.growth)
        try? ctx.save()
        return .grew(added: Economy.fertilizerGrowth, newStage: after > before ? after : nil)
    }

    // MARK: - Parent actions

    static func checkInsNeedingReview(_ checkIns: [CheckIn], _ entries: [LedgerEntry]) -> [CheckIn] {
        let pendingIDs = Set(entries.filter(\.pending).compactMap(\.checkInID))
        return checkIns
            .filter { !$0.reviewed && (pendingIDs.contains($0.id) || ($0.suspicious && !$0.verified)) }
            .sorted { $0.date > $1.date }
    }

    static func approve(_ checkIn: CheckIn, ctx: ModelContext) {
        for e in fetch(LedgerEntry.self, ctx) where e.checkInID == checkIn.id && e.pending {
            e.pending = false
        }
        checkIn.verified = true
        checkIn.reviewed = true
        try? ctx.save()
    }

    static func reject(_ checkIn: CheckIn, ctx: ModelContext) {
        for e in fetch(LedgerEntry.self, ctx) where e.checkInID == checkIn.id && e.pending {
            ctx.delete(e)
        }
        checkIn.isRecord = false
        checkIn.reviewed = true
        try? ctx.save()
    }

    /// 孩子申请提现/使用屏幕时间。不能超过「余额 − 已在申请中的金额」。
    @discardableResult
    static func requestRedemption(_ currency: Currency, amount: Double, ctx: ModelContext) -> Bool {
        guard amount > 0 else { return false }
        let s = settings(ctx)
        let entries = fetch(LedgerEntry.self, ctx)
        let open = fetch(RedemptionRequest.self, ctx)
            .filter { !$0.done && $0.currencyRaw == currency.rawValue }
            .reduce(0) { $0 + $1.amount }
        guard balance(currency, entries, settings: s) - open >= amount else { return false }
        ctx.insert(RedemptionRequest(currency: currency, amount: amount))
        try? ctx.save()
        return true
    }

    static func completeRedemption(_ r: RedemptionRequest, ctx: ModelContext) {
        let reason = r.currency == .money ? "提现 · 已兑现" : "使用屏幕时间 · 已兑现"
        ctx.insert(LedgerEntry(currency: r.currency, amount: -r.amount, reason: reason))
        r.done = true
        r.doneAt = .now
        try? ctx.save()
    }

    // MARK: - Goal suggestions

    static func goalSuggestions(tasks: [SportTask], checkIns: [CheckIn], childName: String) -> [GoalSuggestion] {
        tasks.filter(\.isActive).compactMap { (t: SportTask) -> GoalSuggestion? in
            let recent = checkIns.filter { $0.taskID == t.id }.sorted { $0.date > $1.date }
            if recent.count >= 5, recent.prefix(5).allSatisfy({ $0.value >= t.target * 1.1 }) {
                let nt = t.kind == .rope ? t.target + 10 : t.target + 0.5
                return GoalSuggestion(task: t, newTarget: nt, raise: true,
                                      text: "\(childName)连续 5 次超过目标，要把\(t.kind.title)目标提到 \(nt.clean) \(t.kind.unit)吗？")
            }
            if recent.count >= 3, recent.prefix(3).allSatisfy({ $0.value < t.target }) {
                let nt = t.kind == .rope ? max(30, t.target - 20) : max(0.5, t.target - 0.5)
                return GoalSuggestion(task: t, newTarget: nt, raise: false,
                                      text: "\(childName)连续 3 次没达标，要把\(t.kind.title)目标降到 \(nt.clean) \(t.kind.unit)吗？")
            }
            return nil
        }
    }

    // MARK: - Medals

    static func stats(checkIns: [CheckIn], tree: TreeState) -> MedalStats {
        let valid = checkIns.filter { !$0.suspicious || $0.verified }
        var s = MedalStats()
        s.activeDays = Set(valid.map { calendar.startOfDay(for: $0.date) }).count
        s.ropeTotal = valid.filter { $0.kind == .rope }.reduce(0) { $0 + $1.value }
        s.runTotal = valid.filter { $0.kind == .run }.reduce(0) { $0 + $1.value }
        s.stage = Economy.stage(for: tree.growth)
        s.anyReached = valid.contains { $0.reached }
        s.hasRecord = valid.contains { $0.isRecord && $0.verified }
        s.earlyBird = valid.contains { calendar.component(.hour, from: $0.date) < 8 }
        let byWeek = Dictionary(grouping: valid, by: { weekKey($0.date) })
        s.weekendFull = byWeek.values.contains { list in
            let wd = Set(list.map { calendar.component(.weekday, from: $0.date) })
            return wd.contains(7) && wd.contains(1)
        }
        return s
    }

    /// 判定新勋章并写入，返回新获得的勋章 id
    @discardableResult
    static func evaluateMedals(ctx: ModelContext, now: Date = .now) -> [String] {
        let have = Set(fetch(MedalRecord.self, ctx).map(\.medalID))
        let s = stats(checkIns: fetch(CheckIn.self, ctx), tree: tree(ctx))
        var new: [String] = []
        for d in MedalCatalog.all where !have.contains(d.id) && d.earned(s) {
            ctx.insert(MedalRecord(medalID: d.id, earnedAt: now))
            new.append(d.id)
        }
        if !new.isEmpty { try? ctx.save() }
        return new
    }

    // MARK: - Decorations

    enum BuyResult: Equatable {
        case bought
        case alreadyOwned
        case noCoins(need: Int)
        case locked(stage: Int)
        case unknown
    }

    /// 用金币买一件装饰；买下后自动换上（替换同一位置原来那件）
    @discardableResult
    static func buyDecoration(_ id: String, ctx: ModelContext, now: Date = .now) -> BuyResult {
        guard let item = DecorCatalog.item(id) else { return .unknown }
        let owned = fetch(OwnedDecoration.self, ctx)
        if owned.contains(where: { $0.itemID == id }) { return .alreadyOwned }
        let stageNow = Economy.stage(for: tree(ctx).growth)
        if stageNow < item.minStage { return .locked(stage: item.minStage) }
        let coins = Int(balance(.coins, fetch(LedgerEntry.self, ctx)))
        if coins < item.price { return .noCoins(need: item.price - coins) }

        ctx.insert(LedgerEntry(currency: .coins, amount: -Double(item.price), reason: "装饰：\(item.name)", date: now))
        let record = OwnedDecoration(itemID: id, purchasedAt: now)
        ctx.insert(record)
        equip(record, among: owned)
        try? ctx.save()
        return .bought
    }

    /// 换上一件已拥有的装饰，同一位置的其他装饰自动取下
    static func equipDecoration(_ id: String, ctx: ModelContext) {
        let owned = fetch(OwnedDecoration.self, ctx)
        guard let record = owned.first(where: { $0.itemID == id }) else { return }
        equip(record, among: owned)
        try? ctx.save()
    }

    static func unequipDecoration(_ id: String, ctx: ModelContext) {
        fetch(OwnedDecoration.self, ctx).filter { $0.itemID == id }.forEach { $0.equipped = false }
        try? ctx.save()
    }

    private static func equip(_ record: OwnedDecoration, among owned: [OwnedDecoration]) {
        guard let slot = record.item?.slot else { return }
        for o in owned where o.item?.slot == slot { o.equipped = false }
        record.equipped = true
    }

    /// 当前换上的装饰：位置 → 装饰 id
    static func equippedDecorations(_ owned: [OwnedDecoration]) -> [DecorSlot: String] {
        var map: [DecorSlot: String] = [:]
        for o in owned where o.equipped {
            if let slot = o.item?.slot { map[slot] = o.itemID }
        }
        return map
    }
}
