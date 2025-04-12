////import Foundation
//import UserNotifications
//
//class GoalNotificationManager {
//    static let shared = GoalNotificationManager()
//    
//    func requestPermission() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
//            print("Notification permission granted: \(granted)")
//        }
//    }
//    
//    func scheduleGoalReminder(for goal: FinancialGoal) {
//        let content = UNMutableNotificationContent()
//        content.title = "Напоминание о финансовой цели"
//        content.body = "Цель '\(goal.name)' должна быть достигнута к \(formatDate(goal.deadline))"
//        content.sound = .default
//        
//        let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: goal.deadline)!
//        let components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
//        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
//        
//        let request = UNNotificationRequest(identifier: goal.id.uuidString, content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request)
//    }
//    
//    func notifyGoalAchieved(for goal: FinancialGoal) {
//        let content = UNMutableNotificationContent()
//        content.title = "Поздравляем!"
//        content.body = "Вы достигли своей цели: \(goal.name). Отличная работа!"
//        content.sound = .default
//        
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        let request = UNNotificationRequest(identifier: "goal_achieved_\(goal.id.uuidString)", content: content, trigger: trigger)
//        
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Failed to schedule goal achieved notification: \(error)")
//            } else {
//                print("Goal achieved notification scheduled successfully.")
//            }
//        }
//    }
//    
//    private func formatDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        return formatter.string(from: date)
//        formatter.dateStyle = .medium
//    }
//}
//        return formatter.string(from: date)
//    }
//}
