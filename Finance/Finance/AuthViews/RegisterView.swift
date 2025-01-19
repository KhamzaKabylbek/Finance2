import SwiftUI

struct RegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.plus")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color.primary)
                    .padding(.top, 40)
                
                Text("Создание аккаунта")
                    .font(.system(size: 28, weight: .bold))
                
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
                
                CustomTextField(
                    title: "Подтвердите пароль",
                    text: $confirmPassword,
                    isSecure: true,
                    errorMessage: confirmPasswordError
                )
                
                VStack(spacing: 16) {
                    Button(action: validateAndRegister) {
                        ZStack {
                            Rectangle()
                                .fill(Color.adaptiveButtonColor)
                                .cornerRadius(10)
                            
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Зарегистрироваться")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 50)
                    .padding(.horizontal)
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Уже есть аккаунт? Войти")
                            .foregroundColor(Color.primary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(Color.primary)) // Цвет кнопки "Закрыть" черный
        }
    }
    
    private func validateAndRegister() {
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        
        if !ValidationManager.isValidEmail(email) {
            emailError = "Введите корректный email"
            return
        }
        
        if let passError = ValidationManager.getPasswordErrorMessage(password) {
            passwordError = passError
            return
        }
        
        if password != confirmPassword {
            confirmPasswordError = "Пароли не совпадают"
            return
        }
        
        authViewModel.register(email: email, password: password)
        presentationMode.wrappedValue.dismiss()
    }
}
