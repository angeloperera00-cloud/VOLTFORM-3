import Foundation
import UserNotifications

enum NotificationService {

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleMuscleReadyReminder(muscle: MuscleGroup, readyBy: Date) {
        guard readyBy > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(muscle.rawValue) is ready to train"
        content.body = "Your \(muscle.rawValue.lowercased()) has fully recovered. Time to plan your next session."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: readyBy)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "recovery\(muscle.rawValue)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleWorkoutReminder(at date: Date, workoutName: String) {
        guard date > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = "Time to train"
        content.body = "\(workoutName) is on your plan today. Let's go."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "workout-\(workoutName)-\(date.timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
