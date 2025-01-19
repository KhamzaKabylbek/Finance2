//
//  ContentView.swift
//  Finance
//
//  Created by Хамза Кабылбек on 11.12.2024.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TransactionStore
    @State private var showingAddTransaction = false
    @State private var showingAnalytics = false
    @State private var showingSettings = false
    @State private var selectedTransactionType: TransactionType = .expense
    @StateObject private var goalStore = GoalStore()
    @State private var showingAIAssistant = false
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingDebtors = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Мой бюджет")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryText)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Текущий баланс")
                                .captionTextStyle()
                            Text(store.formatAmount(store.totalBalance))
                                .balanceTextStyle()
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                        .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                selectedTransactionType = .income
                                showingAddTransaction = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down")
                                    Text("Доход")
                                }
                            }
                            .transactionButtonStyle(isIncome: true)
                            .frame(width: 140)
                            
                            Button(action: {
                                selectedTransactionType = .expense
                                showingAddTransaction = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.up")
                                    Text("Расход")
                                }
                            }
                            .transactionButtonStyle(isIncome: false)
                            .frame(width: 140)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                    }
                    .padding(.top)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Последние транзакции")
                            .font(.headline)
                            .foregroundColor(.primaryText)
                            .padding(.horizontal)
                            .padding(.top, 24)
                        
                        List {
                            ForEach(groupedTransactions, id: \.0) { date, transactions in
                                Section {
                                    ForEach(transactions) { transaction in
                                        TransactionRowNew(transaction: transaction)
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets())
                                            .listRowBackground(Color.clear)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        store.deleteTransaction(transaction)
                                                    }
                                                } label: {
                                                    Label("Удалить", systemImage: "trash")
                                                }
                                            }
                                    }
                                } header: {
                                    dateHeader(for: date)
                                        .listRowInsets(EdgeInsets())
                                        .listSectionSeparator(.hidden)
                                        .padding(.top, -12)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
                
                // Add floating AI button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAIAssistant = true
                        }) {
                            Image(systemName: "brain")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.accent)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarItems(
                leading: Button(action: { showingAnalytics = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.pie.fill")
                        Text("Аналитика")
                    }
            
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accent.opacity(0.1))
                    .cornerRadius(20)
                    .foregroundColor(.accent)
                },
                trailing: Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(.primaryText)
                }
            )
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(type: selectedTransactionType)
                    .environmentObject(store)
            }
            .fullScreenCover(isPresented: $showingAnalytics) {
                AnalyticsView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(goalStore: GoalStore())
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingAIAssistant) {
                AIChatView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDebtors = true }) {
                        Image(systemName: "person.badge.clock")
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                    .background(Color.accent.opacity(0.1))
                    .cornerRadius(40)
                    .foregroundColor(.accent)
                }
            }
            .sheet(isPresented: $showingDebtors) {
                NavigationView {
                    DebtorsView()
                }
            }
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
    
    var groupedTransactions: [(Date, [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.transactions.reversed()) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    func dateHeader(for date: Date) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isYesterday = calendar.isDateInYesterday(date)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "d MMMM"
        
        let dateString: String
        if isToday {
            dateString = "Сегодня"
        } else if isYesterday {
            dateString = "Вчера"
        } else {
            dateString = dateFormatter.string(from: date)
        }
        
        return ZStack {
            Color.clear
            HStack {
                Spacer()
                Text(dateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                Spacer()
            }
        }
        .padding(.bottom, 4)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .standardShadow()
        }
    }
}

struct TransactionRowNew: View {
    @EnvironmentObject var store: TransactionStore
    let transaction: Transaction
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: transaction.category.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: transaction.category.color))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.category.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                    if !transaction.note.isEmpty {
                        Text(transaction.note)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    if isExpanded {
                        Text(formatDate(transaction.date)) // Показываем дату, если ячейка развернута
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                Text("\(transaction.type == .income ? "+" : "-")\(store.formatAmount(transaction.amount))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.type == .income ? .incomeGreen : .expenseRed)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color.cardBackground)
            .cornerRadius(12)
            //.standardShadow()
            .padding(.horizontal)
            .padding(.vertical, 4)
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle() // Переключаем состояние при нажатии
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(TransactionStore())
}
