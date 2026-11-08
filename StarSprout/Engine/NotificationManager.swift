import Foundation
import SwiftData
import UserNotifications

/// 本地通知：不需要服务器。每次打开 App、打卡、改任务后重排未来 7 天的提醒，
/// 当天已经运动过的提醒会被跳过。
enum NotificationManager {
    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

        static func reschedule(ctx: ModelContext, now: Date = .now) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let cal = GameEngine.calendar
        let s = GameEngine.settings(ctx)
        let tasks = GameEngine.fetch(SportTask.self, ctx).filter(\.isActive)
        let checkIns = GameEngine.fetch(CheckIn.self, ctx)
        let exercisedToday = GameEngine.exercisedToday(checkIns, now: now)

        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now)) else { continue }
            let weekday = cal.component(.weekday, from: day)
            let isToday = offset == 0

            for t in tasks where t.weekdays.contains(weekday) {
                if isToday && checkIns.contains(where: { $0.taskID == t.id && cal.isDate($0.date, inSameDayAs: now) }) {
                    continue
                }
                guard let fire = cal.date(bySettingHour: t.reminderHour, minute: t.reminderMinute, second: 0, of: day),
                      fire > now else { continue }
                add(id: "task-\(t.id.uuidString)-\(offset)",
                    title: "该\(t.kind.title)啦",
                    body: "\(t.targetText)。运动后水壶就会装满，小树在等你",
                    at: fire)
            }

            if isToday && exercisedToday { continue }
            if let fire = cal.date(bySettingHour: s.eveningReminderHour, minute: 0, second: 0, of: day), fire > now {
                add(id: "evening-\(offset)",
                    title: "今天还没运动哦",
                    body: "提醒\(s.childName)动一动，小树今天还没喝到水",
                    at: fire)
            }
        }
    }

    private static func add(id: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let comps = GameEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(identifier: id, content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
}
