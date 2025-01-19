import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("Notification permission granted: \(granted)")
        }
    }
    
    func scheduleMilestoneNotification(for goal: FinancialGoal, milestone: Double) {
        let content = UNMutableNotificationContent()
        let percentage = Int(milestone * 100)
        content.title = "Поздравляем! 🎉"
        content.body = "Вы достигли \(percentage)% вашей цели '\(goal.name)'!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "\(goal.id)-\(percentage)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleDeadlineReminder(for goal: FinancialGoal) {
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о цели"
        content.body = "До достижения цели '\(goal.name)' осталось 3 дня"
        content.sound = .default
        
        let triggerDate = Calendar.current.date(byAdding: .day, value: -3, to: goal.deadline)!
        let components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(goal.id)-deadline",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleWeeklyProgressNotification(for goal: FinancialGoal) {
        let content = UNMutableNotificationContent()
        let remainingAmount = goal.targetAmount - goal.currentAmount
        content.title = "Еженедельный отчет по цели"
        content.body = "Цель '\(goal.name)': накоплено \(Int(goal.progress * 100))%. Осталось накопить: \(remainingAmount)"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 10 // 10:00
        dateComponents.weekday = 1 // Воскресенье
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "\(goal.id)-weekly",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
