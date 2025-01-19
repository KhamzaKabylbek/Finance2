import Foundation

struct Settings: Codable {
    var isDarkMode: Bool
    var currency: Currency
    var financialGoals: [FinancialGoal]
    
    enum Currency: String, CaseIterable, Codable {
        case kzt = "₸"
        case usd = "$"
        case eur = "€"
        case rub = "₽"
        
        var name: String {
            switch self {
            case .kzt: return "Тенге"
            case .usd: return "Доллар США"
            case .eur: return "Евро"
            case .rub: return "Рубль"
            }
        }
    }
    
    static let defaultSettings = Settings(
        isDarkMode: false,
        currency: .kzt,
        financialGoals: []
    )
} 