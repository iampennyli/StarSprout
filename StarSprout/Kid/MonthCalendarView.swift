import SwiftUI

/// 按自然月展示打卡：跳绳、跑步用不同图标点亮，没打卡的日子留空，不标红叉
struct MonthCalendarView: View {
    let checkIns: [CheckIn]
    var weeklyBonusDays: Int = 5
    var now: Date = .now

    private var cal: Calendar { GameEngine.calendar }

    private struct DayCell: Identifiable {
        let id: Int
        let day: Int?
        let rope: Bool
        let run: Bool
        let isToday: Bool
        let isFuture: Bool
    }

    private var monthCheckIns: [CheckIn] {
        checkIns.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }
    }

    private var cells: [DayCell] {
        guard let interval = cal.dateInterval(of: .month, for: now),
              let range = cal.range(of: .day, in: .month, for: now) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start)   // 1=周日
        let leading = (firstWeekday + 5) % 7                                // 周一开头需要空几格
        let todayNum = cal.component(.day, from: now)
        var byDay: [Int: Set<SportKind>] = [:]
        for c in monthCheckIns { byDay[cal.component(.day, from: c.date), default: []].insert(c.kind) }

        var result: [DayCell] = (0..<leading).map { DayCell(id: -$0 - 1, day: nil, rope: false, run: false, isToday: false, isFuture: false) }
        for d in range {
            let kinds = byDay[d] ?? []
            result.append(DayCell(id: d, day: d, rope: kinds.contains(.rope), run: kinds.contains(.run),
                                  isToday: d == todayNum, isFuture: d > todayNum))
        }
        return result
    }

    var body: some View {
        let monthDays = Set(monthCheckIns.map { cal.startOfDay(for: $0.date) }).count
        let ropeDays = Set(monthCheckIns.filter { $0.kind == .rope }.map { cal.startOfDay(for: $0.date) }).count
        let runDays = Set(monthCheckIns.filter { $0.kind == .run }.map { cal.startOfDay(for: $0.date) }).count
        let weekDays = GameEngine.activeDaysThisWeek(checkIns, now: now)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(cal.component(.month, from: now)) 月").font(Theme.titleFont(22))
                Spacer()
                Text(weekDays >= weeklyBonusDays
                     ? "本月 \(monthDays) 天 · 本周全勤达成"
                     : "本月 \(monthDays) 天 · 本周 \(weekDays)/\(weeklyBonusDays)，再 \(weeklyBonusDays - weekDays) 天拿全勤")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
            HStack(spacing: 14) {
                legend(kind: .rope, text: "跳绳 \(ropeDays) 天")
                legend(kind: .run, text: "跑步 \(runDays) 天")
            }
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) {
                    Text($0).font(.caption2).foregroundStyle(Theme.muted)
                }
                ForEach(cells) { cell in dayView(cell) }
            }
        }
        .card(padding: 14, radius: 22)
    }

    private func legend(kind: SportKind, text: String) -> some View {
        HStack(spacing: 4) {
            KindBadge(kind: kind)
            Text(text).font(.caption).foregroundStyle(Theme.muted)
        }
    }

    @ViewBuilder
    private func dayView(_ c: DayCell) -> some View {
        if let d = c.day {
            VStack(spacing: 1) {
                Text("\(d)").font(.system(size: 10)).foregroundStyle(c.isFuture ? Theme.dim : .white)
                HStack(spacing: 2) {
                    if c.rope { KindBadge(kind: .rope) }
                    if c.run { KindBadge(kind: .run) }
                }
                .frame(height: 16)
            }
            .frame(maxWidth: .infinity, minHeight: 38)
            .background((c.rope || c.run) ? Theme.cardRaised : Color.clear, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(c.isToday ? Theme.lime : .clear, lineWidth: 2))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(d) 日" + (c.rope ? "，跳绳" : "") + (c.run ? "，跑步" : ""))
        } else {
            Color.clear.frame(minHeight: 38)
        }
    }
}

struct KindBadge: View {
    let kind: SportKind
    var body: some View {
        Image(systemName: kind.symbol)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Theme.ink)
            .frame(width: 16, height: 16)
            .background(kind == .rope ? Theme.lime : Theme.cyan, in: Circle())
    }
}
