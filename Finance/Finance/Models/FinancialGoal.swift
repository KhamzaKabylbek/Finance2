import Foundation

struct FinancialGoal: Identifiable, Codable {
    var id = UUID()
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date
    var category: Category?
    var createdAt: Date = Date()
    var autoSavePercentage: Double // Процент автоматического сохранения от доходов
    var milestoneNotifications: Bool // Включить/выключить уведомления о достижениях
    var transactions: [GoalTransaction] // История транзакций для цели
    
    var progress: Double {
        min(currentAmount / targetAmount, 1.0)
    }
    
    var isCompleted: Bool {
        currentAmount >= targetAmount
    }
    
    var isOverdue: Bool {
        !isCompleted && Date() > deadline
    }
    
    var averageSavingRate: Double {
        guard !transactions.isEmpty else { return 0 }
        let totalDays = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 1
        return currentAmount / Double(totalDays)
    }
    
    var estimatedCompletionDate: Date? {
        guard !isCompleted && averageSavingRate > 0 else { return nil }
        let remainingAmount = targetAmount - currentAmount
        let daysRemaining = remainingAmount / averageSavingRate
        return Calendar.current.date(byAdding: .day, value: Int(daysRemaining), to: Date())
    }
    
    var nextMilestone: Double {
        let milestones = [0.25, 0.5, 0.75, 1.0]
        return milestones.first { $0 > progress } ?? 1.0
    }
    
    init(id: UUID = UUID(), name: String, targetAmount: Double, currentAmount: Double = 0, 
         deadline: Date, category: Category? = nil, autoSavePercentage: Double = 10, 
         milestoneNotifications: Bool = true) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.category = category
        self.autoSavePercentage = autoSavePercentage
        self.milestoneNotifications = milestoneNotifications
        self.transactions = []
    }
    
    mutating func addProgress(_ amount: Double) {
        let oldProgress = progress
        currentAmount += amount
        transactions.append(GoalTransaction(amount: amount, date: Date()))
        
        // Проверяем, достигнут ли новый milestone
        if milestoneNotifications {
            let newProgress = progress
            let milestones = [0.25, 0.5, 0.75, 1.0]
            for milestone in milestones {
                if oldProgress < milestone && newProgress >= milestone {
                    NotificationManager.shared.scheduleMilestoneNotification(for: self, milestone: milestone)
                }
            }
        }
    }
}

struct GoalTransaction: Codable {
    let amount: Double
    let date: Date
}