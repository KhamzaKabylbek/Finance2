import Foundation
import UserNotifications

class GoalNotificationManager {
    static let shared = GoalNotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("Notification permission granted: \(granted)")
        }
    }
    
    func scheduleGoalReminder(for goal: FinancialGoal) {
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о финансовой цели"
        content.body = "Цель '\(goal.name)' должна быть достигнута к \(formatDate(goal.deadline))"
        content.sound = .default
        
        let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: goal.deadline)!
        let components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: goal.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 