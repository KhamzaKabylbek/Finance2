import Foundation

struct FinancialGoal: Identifiable, Codable {
    var id = UUID()
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date
    var category: Category?
    var createdAt: Date = Date()
    
    var progress: Double {
        min(currentAmount / targetAmount, 1.0)
    }
    
    var isCompleted: Bool {
        currentAmount >= targetAmount
    }
    
    var isOverdue: Bool {
        !isCompleted && Date() > deadline
    }
} 