import Foundation
import SwiftUI

typealias Currency = Settings.Currency

class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var settings: Settings = Settings.defaultSettings
    
    private let transactionsKey = "savedTransactions"
    private let categoriesKey = "savedCategories"
    private let settingsKey = "savedSettings"
    
    init() {
        loadData()
        categories = Category.defaultCategories
        saveData()
    }
    
    var totalBalance: Double {
        transactions.reduce(0) { total, transaction in
            switch transaction.type {
            case .income: return total + transaction.amount
            case .expense: return total - transaction.amount
            }
        }
    }
    
    // Транзакции
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveData()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        saveData()
    }
    
    // Категории
    func addCategory(_ category: Category) {
        categories.append(category)
        saveData()
    }
    
    func resetCategories() {
        categories = Category.defaultCategories
        saveData()
    }
    
    // Финансовые цели
    func addGoal(_ goal: FinancialGoal) {
        settings.financialGoals.append(goal)
        saveData()
    }
    
    func updateGoal(_ goal: FinancialGoal) {
        if let index = settings.financialGoals.firstIndex(where: { $0.id == goal.id }) {
            settings.financialGoals[index] = goal
            saveData()
        }
    }
    
    func deleteGoal(_ goal: FinancialGoal) {
        settings.financialGoals.removeAll { $0.id == goal.id }
        saveData()
    }
    
    // Форматирование и настройки
    func formatAmount(_ amount: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        
        if let formattedAmount = numberFormatter.string(from: NSNumber(value: amount)) {
            return "\(settings.currency.rawValue)\(formattedAmount)"
        }
        
        return "\(settings.currency.rawValue)0.00"
    }
    
    func updateCurrency(_ currency: Currency) {
        settings.currency = currency
        saveData()
    }
    
    // Сохранение и загрузка данных
    private func saveData() {
        if let encodedTransactions = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encodedTransactions, forKey: transactionsKey)
        }
        
        if let encodedCategories = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encodedCategories, forKey: categoriesKey)
        }
        
        if let encodedSettings = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encodedSettings, forKey: settingsKey)
        }
    }
    
    private func loadData() {
        if let savedTransactions = UserDefaults.standard.data(forKey: transactionsKey),
           let decodedTransactions = try? JSONDecoder().decode([Transaction].self, from: savedTransactions) {
            transactions = decodedTransactions
        }
        
        if let savedCategories = UserDefaults.standard.data(forKey: categoriesKey),
           let decodedCategories = try? JSONDecoder().decode([Category].self, from: savedCategories) {
            categories = decodedCategories
        }
        
        if let savedSettings = UserDefaults.standard.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(Settings.self, from: savedSettings) {
            settings = decodedSettings
        }
    }
} 
