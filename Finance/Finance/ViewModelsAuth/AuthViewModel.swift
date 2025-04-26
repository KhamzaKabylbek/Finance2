import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Тестовые данные
    private let testEmail = "t1@example.com"
    private let testPassword = "t1@example.com"
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // Check for test credentials
        if email == testEmail && password == testPassword {
            DispatchQueue.main.async {
                self.isLoading = false
                self.isAuthenticated = true
                self.currentUser = User(email: email)
                print("Login successful with test credentials")
                return
            }
            return
        }
        
        let url = URL(string: "http://185.4.180.149:8080/open-api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["login": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Ошибка: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                    self.errorMessage = "Неизвестная ошибка"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let token = json["token"] as? String {
                        self.isAuthenticated = true
                        self.currentUser = User(email: email)
                        print("Login successful, token: \(token)")
                    } else {
                        self.errorMessage = "Неверный формат ответа сервера"
                    }
                } else {
                    self.errorMessage = "Эта почта не зарегистрирована или пароль неверный"
                }
            }
        }.resume()
    }
    
    func register(email: String, password: String) {
        isLoading = true
        let url = URL(string: "http://185.4.180.149:8080/open-api/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "fullName": "Хамза", "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("Registration error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else { return }
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let email = json["email"] as? String {
                    self.isAuthenticated = true
                    self.currentUser = User(email: email)
                    print("Registration successful for email: \(email)")
                } else {
                    print("Invalid registration response")
                }
            }
        }.resume()
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
    }
}
