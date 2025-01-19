import Foundation

enum TransactionType: String, Codable {
    case income = "income"
    case expense = "expense"
}

struct Transaction: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var category: Category
    var date: Date
    var note: String
    var type: TransactionType
    var isRecurring: Bool
    var recurringInterval: RecurringInterval?
    
    enum RecurringInterval: String, Codable {
        case daily, weekly, monthly, yearly
    }
} 