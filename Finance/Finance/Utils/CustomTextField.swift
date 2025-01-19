//
//  CustomTextField.swift
//  Finance
//
//  Created by Хамза Кабылбек on 18.01.2025.
//

import SwiftUI

struct CustomTextField: View {
    let title: String
    let text: Binding<String>
    let isSecure: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isSecure {
                SecureField(title, text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(errorMessage != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                TextField(title, text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(errorMessage != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
        }
        .padding(.horizontal)
    }
}
