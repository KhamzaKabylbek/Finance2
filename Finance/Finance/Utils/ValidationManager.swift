import Foundation

struct ValidationManager {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        // Минимум 6 символов
        guard password.count >= 6 else { return false }
        
        // Содержит хотя бы одну цифру
        let numberRegex = ".*[0-9]+.*"
        let numberPred = NSPredicate(format:"SELF MATCHES %@", numberRegex)
        guard numberPred.evaluate(with: password) else { return false }
        
        // Содержит хотя бы одну букву
        let letterRegex = ".*[A-Za-z]+.*"
        let letterPred = NSPredicate(format:"SELF MATCHES %@", letterRegex)
        return letterPred.evaluate(with: password)
    }
    
    static func getPasswordErrorMessage(_ password: String) -> String? {
        if password.isEmpty {
            return "Пароль не может быть пустым"
        }
        if password.count < 6 {
            return "Пароль должен содержать минимум 6 символов"
        }
        if !password.contains(where: { $0.isNumber }) {
            return "Пароль должен содержать хотя бы одну цифру"
        }
        if !password.contains(where: { $0.isLetter }) {
            return "Пароль должен содержать хотя бы одну букву"
        }
        return nil
    }
}
