import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegistration = false
    @State private var showForgotPassword = false
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            
            Image(systemName: "dollarsign.circle")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(Color.primary) // Changed from Color(white: 0.2)
                .symbolRenderingMode(.monochrome)
                .padding(.top, 40)
                
            Text("Добро пожаловать")
                .font(.system(size: 28, weight: .bold))
            
            Text("Войдите в свой аккаунт")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            CustomTextField(
                title: "Email",
                text: $email,
                isSecure: false,
                errorMessage: emailError
            )
            
            CustomTextField(
                title: "Пароль",
                text: $password,
                isSecure: true,
                errorMessage: passwordError
            )
            
            Button(action: {
                showForgotPassword = true
            }) {
                Text("Забыли пароль?")
                    .font(.subheadline)
                    .foregroundColor(.primary) // Changed from .black
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button(action: validateAndLogin) {
                    ZStack {
                        Rectangle()
                            .fill(Color.adaptiveButtonColor)
                            .cornerRadius(10)
                        
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Войти")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 50)
                .padding(.horizontal)
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        showRegistration = true
                    }
                }) {
                    Text("Зарегистрироваться")
                        .foregroundColor(.primary) // Changed from .black
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showRegistration) {
            RegisterView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView() // Создайте представление ForgotPasswordView
        }
    }
    
    private func validateAndLogin() {
        emailError = nil
        passwordError = nil
        
        if !ValidationManager.isValidEmail(email) {
            emailError = "Введите корректный email"
            return
        }
        
        if let passError = ValidationManager.getPasswordErrorMessage(password) {
            passwordError = passError
            return
        }
        
        authViewModel.login(email: email, password: password)
    }
}
