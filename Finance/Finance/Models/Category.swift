import SwiftUI

struct Category: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var color: String
    var type: TransactionType
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
    
    static let defaultCategories: [Category] = [
        Category(name: "Покушать", icon: "fork.knife", color: "#FF9500", type: .expense),
        Category(name: "Продукты", icon: "cart.fill", color: "#4A90E2", type: .expense),
        Category(name: "Транспорт", icon: "car.fill", color: "#F5A623", type: .expense),
        Category(name: "Развлечения", icon: "film.fill", color: "#7ED321", type: .expense),
        Category(name: "Кафе", icon: "cup.and.saucer.fill", color: "#D0021B", type: .expense),
        Category(name: "Здоровье", icon: "heart.fill", color: "#BD10E0", type: .expense),
        Category(name: "Комуналка", icon: "house", color: "#F8E71C", type: .expense),
        Category(name: "Спорт", icon: "figure.run", color: "#4A4A4A", type: .expense),
        
        Category(name: "Подработка", icon: "briefcase.fill", color: "#34C759", type: .income),
        Category(name: "Зарплата", icon: "dollarsign.circle.fill", color: "#50E3C2", type: .income),
        Category(name: "Фриланс", icon: "laptopcomputer", color: "#9013FE", type: .income),
        Category(name: "Подарки", icon: "gift.fill", color: "#F8E71C", type: .income)
    ]
} 
