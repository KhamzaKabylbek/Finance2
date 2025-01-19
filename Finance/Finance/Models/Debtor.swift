import Foundation

struct Debtor: Identifiable, Codable {
    var id: UUID
    var name: String
    var phoneNumber: String
    var amount: Double
    var currency: Settings.Currency
    var note: String
    var deadline: Date?
    var isPaid: Bool
    
    init(id: UUID = UUID(), name: String, phoneNumber: String, amount: Double, currency: Settings.Currency = .kzt, note: String = "", deadline: Date? = nil, isPaid: Bool = false) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.amount = amount
        self.currency = currency
        self.note = note
        self.deadline = deadline
        self.isPaid = isPaid
    }
    
    var formattedAmount: String {
        return String(format: "%.2f %@", amount, currency.rawValue)
    }
}
