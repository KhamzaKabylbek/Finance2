import SwiftUI

// Инициализация цвета из hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Расширение для View с стилями
extension View {
    func standardShadow() -> some View {
        self.shadow(
            color: Color(UIColor.label).opacity(0.08),
            radius: 15,
            x: 0,
            y: 5
        )
    }
    
    func standardCornerRadius() -> some View {
        self.cornerRadius(16)
    }
    
    func cardGradientBackground() -> some View {
        self.background(Color.cardBackground)
    }
    
    func cardStyle() -> some View {
        self
            .cardGradientBackground()
            .standardCornerRadius()
            .standardShadow()
    }
    
    func balanceTextStyle() -> some View {
        self
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.primaryText)
    }
    
    func captionTextStyle() -> some View {
        self
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondaryText)
    }
    
    func transactionButtonStyle(isIncome: Bool) -> some View {
        self
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(isIncome ? Color.incomeGreen : Color.expenseRed)
            .cornerRadius(12)
            .shadow(
                color: (isIncome ? Color.incomeGreen : Color.expenseRed).opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
    }
    
    func balanceCardStyle() -> some View {
        self
            .background(Color.balanceBackground)
            .standardCornerRadius()
            .standardShadow()
    }
    
    func transactionCardStyle() -> some View {
        self
            .background(Color.transactionBackground)
            .standardCornerRadius()
            .standardShadow()
    }
}

// Определение цветов для темной и светлой темы
extension Color {
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    static let primaryBackground = Color.dynamicColor(light: Color(hex: "F5F6FA"), dark: Color(hex: "1C1C1E"))
    static let cardBackground = Color.dynamicColor(light: Color(hex: "FFFFFF"), dark: Color(hex: "2C2C2E"))
    static let primaryText = Color.dynamicColor(light: Color(hex: "000000"), dark: Color(hex: "FFFFFF"))
    static let secondaryText = Color.dynamicColor(light: Color(hex: "6E6E73"), dark: Color(hex: "8E8E93"))
    static let accent = Color(hex: "5C6CFF")
    static let incomeGreen = Color(hex: "4CAF50")
    static let expenseRed = Color(hex: "FF5252")
    
    // Цвета для баланса
    static let balanceBackground = Color.dynamicColor(light: Color(hex: "FFFFFF"), dark: Color(hex: "2C2C2E").opacity(0.8))
    
    // Цвета для транзакций
    static let transactionBackground = Color.dynamicColor(light: Color(hex: "FFFFFF"), dark: Color(hex: "2C2C2E").opacity(0.7))
}