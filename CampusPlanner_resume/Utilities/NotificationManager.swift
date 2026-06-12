import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() { }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func checkPermission(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    func preparePermission(completion: @escaping (Bool) -> Void) {
        checkPermission { status in
            switch status {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .notDetermined:
                self.requestPermission(completion: completion)
            default:
                completion(false)
            }
        }
    }

    func scheduleNotifications(for task: TaskItem) {
        guard !task.isDone else {
            cancelNotifications(for: task)
            return
        }

        preparePermission { granted in
            guard granted else { return }

            let center = UNUserNotificationCenter.current()
            self.cancelNotifications(for: task)

            let content = UNMutableNotificationContent()
            content.title = "마감 임박: \(task.title)"
            content.body = "\(task.course) 마감: \(self.formattedDate(task.dueDate))"
            content.sound = .default
            content.badge = 1

            if task.notifyDayBefore,
               let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: task.dueDate) {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: dayBefore)
                comps.hour = task.notifyHour
                comps.minute = 0

                if let fireDate = Calendar.current.date(from: comps), fireDate > Date() {
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: task.id.uuidString + "-dayBefore",
                        content: content,
                        trigger: trigger
                    )
                    center.add(request) { error in
                        if let error { print("[Notification] day-before error: \(error)") }
                    }
                }
            }

            if task.dueDate > Date() {
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: task.id.uuidString + "-due",
                    content: content,
                    trigger: trigger
                )
                center.add(request) { error in
                    if let error { print("[Notification] due-date error: \(error)") }
                }
            }
        }
    }

    func cancelNotifications(for task: TaskItem) {
        let ids = [task.id.uuidString + "-dayBefore", task.id.uuidString + "-due"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
