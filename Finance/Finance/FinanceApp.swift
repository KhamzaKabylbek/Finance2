//
//  FinanceApp.swift
//  Finance
//
//  Created by Хамза Кабылбек on 11.12.2024.
//

import SwiftUI

@main
struct FinanceApp: App {
    @StateObject private var store = TransactionStore()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var authViewModel = AuthViewModel()

    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(store)
                    .environmentObject(themeManager)
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
