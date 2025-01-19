import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    // Тестовые данные
    private let testEmail = "t@example.com"
    private let testPassword = "p123456"
    
    func login(email: String, password: String) {
        isLoading = true
        
        // Имитация сетевого запроса
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            if email == self.testEmail && password == self.testPassword {
                self.isAuthenticated = true
                self.currentUser = User(email: email)
            }
            
            self.isLoading = false
        }
    }
    
    func register(email: String, password: String) {
        isLoading = true
        
        // Имитация сетевого запроса
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            self.isAuthenticated = true
            self.currentUser = User(email: email)
            self.isLoading = false
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
    }
}
