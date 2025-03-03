//
//  ForgotPasswordView.swift
//  Finance
//
//  Created by Хамза Кабылбек on 18.01.2025.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var emailError: String? = nil
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "key.icloud")
                    .resizable()
                    .frame(width: 120, height: 100)
                    .foregroundColor(Color.primary) // Оттенок серого (0.2 - почти чёрный)
                    .symbolRenderingMode(.monochrome)
                    .padding(.top, 40)
                
                Text("Восстановление пароля")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Введите ваш email для восстановления пароля")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                CustomTextField(
                    title: "Email",
                    text: $email,
                    isSecure: false,
                    errorMessage: emailError
                ).font(.system(size: 22))
                
                Button(action: validateAndSendResetLink) {
                    ZStack {
                        Rectangle()
                            .fill(Color.adaptiveButtonColor)
                            .cornerRadius(10)
                        
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Отправить ссылку")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 50)
                .padding(.horizontal)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Отмена")
                        .foregroundColor(Color.primary)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            })
            .foregroundColor(Color.primary)
        }
    }
    
    private func validateAndSendResetLink() {
        emailError = nil
        
        if !ValidationManager.isValidEmail(email) {
            emailError = "Введите корректный email"
            return
        }
    }
}
