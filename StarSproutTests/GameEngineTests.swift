import XCTest
import SwiftData
@testable import StarSprout

@MainActor
final class GameEngineTests: XCTestCase {
    private var container: ModelContainer!
    private var ctx: ModelContext!
    private var rope: SportTask!
    private let cal = GameEngine.calendar

    /// 2026-11-09 是周一
    private func day(_ offset: Int, hour: Int = 18) -> Date {
        let monday = cal.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: hour))!
        return cal.date(byAdding: .day, value: offset, to: monday)!
    }

    override func setUp() async throws {
        let schema = Schema(AppSchema.models)
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        ctx = ModelContext(container)
        let s = GameEngine.settings(ctx)
        s.consented = true
        _ = GameEngine.tree(ctx)
        rope = SportTask(kind: .rope, target: 150, rewardType: .money, rewardAmount: 1)
        ctx.insert(rope)
        try ctx.save()
    }

    private var entries: [LedgerEntry] { GameEngine.fetch(LedgerEntry.self, ctx) }

    func testStageThresholds() {
        XCTAssertEqual(Economy.stage(for: 0), 1)
        XCTAssertEqual(Economy.stage(for: 3), 2)
        XCTAssertEqual(Economy.stage(for: 99), 4)
        XCTAssertEqual(Economy.stage(for: 100), 5)
        XCTAssertEqual(Economy.stage(for: 500), 7)
        XCTAssertNil(Economy.stageRange(for: 240))
    }

    func testUnreachedStillGetsWaterButNoCoinsOrMoney() {
        let r = GameEngine.submit(task: rope, value: 120, ctx: ctx, now: day(0))
        XCTAssertTrue(r.gotWater)
        XCTAssertEqual(r.coins, 0)
        XCTAssertEqual(r.realRewardAmount, 0)
        XCTAssertEqual(GameEngine.waterLeft(entries, now: day(0)), 3)
        XCTAssertEqual(GameEngine.balance(.coins, entries), 0)
    }

    func testWaterOnlyOncePerDayAndNotCarriedOver() {
        GameEngine.submit(task: rope, value: 160, ctx: ctx, now: day(0, hour: 8))
        let second = GameEngine.submit(task: rope, value: 160, ctx: ctx, now: day(0, hour: 9))
        XCTAssertFalse(second.gotWater)
        XCTAssertEqual(GameEngine.waterLeft(entries, now: day(0)), 3)
        XCTAssertEqual(GameEngine.waterLeft(entries, now: day(1)), 0)
    }

    func testReachedGivesCoinsImmediatelyAndMoneyPending() {
        let r = GameEngine.submit(task: rope, value: 155, ctx: ctx, now: day(0))
        XCTAssertEqual(r.coins, 10)
        XCTAssertTrue(r.realRewardPending)
        XCTAssertEqual(GameEngine.balance(.coins, entries), 10)
        XCTAssertEqual(GameEngine.balance(.money, entries), 0)
        XCTAssertEqual(GameEngine.pendingAmount(.money, entries), 1)

        GameEngine.approve(r.checkIn, ctx: ctx)
        XCTAssertEqual(GameEngine.balance(.money, entries), 1)
    }

    func testTrustModeConfirmsImmediately() {
        GameEngine.settings(ctx).trustMode = true
        GameEngine.submit(task: rope, value: 155, ctx: ctx, now: day(0))
        XCTAssertEqual(GameEngine.balance(.money, entries), 1)
    }

    func testDailyMoneyCap() {
        GameEngine.settings(ctx).dailyMoneyCap = 2
        GameEngine.settings(ctx).trustMode = true
        for h in 8...11 { GameEngine.submit(task: rope, value: 150, ctx: ctx, now: day(0, hour: h)) }
        XCTAssertEqual(GameEngine.balance(.money, entries), 2)
    }

    func testSuspiciousValueNeedsParentEvenInTrustMode() {
        GameEngine.settings(ctx).trustMode = true
        let r = GameEngine.submit(task: rope, value: 400, ctx: ctx, now: day(0))
        XCTAssertTrue(r.checkIn.suspicious)
        XCTAssertEqual(GameEngine.balance(.coins, entries), 0)
        XCTAssertEqual(GameEngine.checkInsNeedingReview(GameEngine.fetch(CheckIn.self, ctx), entries).count, 1)
        GameEngine.reject(r.checkIn, ctx: ctx)
        XCTAssertEqual(GameEngine.balance(.coins, entries), 0)
    }

    func testUnverifiedSuspiciousValueLeftOutOfRecentChart() {
        GameEngine.submit(task: rope, value: 160, ctx: ctx, now: day(0))
        GameEngine.submit(task: rope, value: 232, ctx: ctx, now: day(1))
        let r = GameEngine.submit(task: rope, value: 170, ctx: ctx, now: day(2))
        XCTAssertEqual(r.recentValues, [160, 170])
        XCTAssertTrue(r.checkIn.isRecord)
    }

    func testSoundFilesAreBundled() {
        XCTAssertNotNil(Bundle.main.url(forResource: "planet_bgm", withExtension: "m4a"))
        for s in SFX.allCases {
            XCTAssertNotNil(Bundle.main.url(forResource: "sfx_\(s.rawValue)", withExtension: "wav"), s.rawValue)
        }
    }

    func testWateringLimitedToThreePerDay() {
        GameEngine.submit(task: rope, value: 100, ctx: ctx, now: day(0))
        for _ in 0..<3 {
            if case .grew = GameEngine.water(ctx: ctx, now: day(0)) {} else { XCTFail("should grow") }
        }
        XCTAssertEqual(GameEngine.water(ctx: ctx, now: day(0)), .noWater)
        XCTAssertEqual(GameEngine.tree(ctx).growth, 3)
    }

    func testFertilizerCostAndCooldown() {
        for i in 0..<3 { GameEngine.submit(task: rope, value: 150, ctx: ctx, now: day(0, hour: 8 + i)) }
        XCTAssertEqual(GameEngine.fertilize(ctx: ctx, now: day(0)), .grew(added: 3, newStage: 2))
        XCTAssertEqual(GameEngine.balance(.coins, entries), 0)
        XCTAssertEqual(GameEngine.fertilize(ctx: ctx, now: day(1)), .cooldown(daysLeft: 2))
    }

    func testWeeklyBonusAtFiveDays() {
        for d in 0..<4 { GameEngine.submit(task: rope, value: 100, ctx: ctx, now: day(d)) }
        XCTAssertFalse(entries.contains { $0.reason.hasPrefix("全勤奖励") })
        let r = GameEngine.submit(task: rope, value: 100, ctx: ctx, now: day(4))
        XCTAssertTrue(r.weeklyBonus)
        let again = GameEngine.submit(task: rope, value: 100, ctx: ctx, now: day(5))
        XCTAssertFalse(again.weeklyBonus)
    }

    func testComebackDoublesFirstWatering() {
        GameEngine.submit(task: rope, value: 100, ctx: ctx, now: day(0))
        GameEngine.submit(task: rope, value: 100, ctx: ctx, now: day(6))   // 6 天没运动 → 打瞌睡
        XCTAssertEqual(GameEngine.water(ctx: ctx, now: day(6)), .grew(added: 2, newStage: nil))
        XCTAssertEqual(GameEngine.water(ctx: ctx, now: day(6)), .grew(added: 1, newStage: 2))
    }

    func testMoodByDays() {
        XCTAssertEqual(TreeMood.from(daysSinceExercise: 2), .normal)
        XCTAssertEqual(TreeMood.from(daysSinceExercise: 3), .thirsty)
        XCTAssertEqual(TreeMood.from(daysSinceExercise: 7), .sleepy)
        XCTAssertEqual(TreeMood.from(daysSinceExercise: 12), .hibernating)
    }

    func testMedalsAreCumulative() {
        GameEngine.submit(task: rope, value: 150, ctx: ctx, now: day(0))
        GameEngine.submit(task: rope, value: 150, ctx: ctx, now: day(2))
        GameEngine.submit(task: rope, value: 150, ctx: ctx, now: day(5))
        let ids = GameEngine.evaluateMedals(ctx: ctx, now: day(5))
        XCTAssertTrue(ids.contains("days3"))
        XCTAssertTrue(ids.contains("firstReach"))
    }

    func testRedemptionCannotExceedBalance() {
        GameEngine.settings(ctx).trustMode = true
        GameEngine.submit(task: rope, value: 150, ctx: ctx, now: day(0))
        XCTAssertFalse(GameEngine.requestRedemption(.money, amount: 5, ctx: ctx))
        XCTAssertTrue(GameEngine.requestRedemption(.money, amount: 1, ctx: ctx))
        XCTAssertFalse(GameEngine.requestRedemption(.money, amount: 1, ctx: ctx))
    }
}
