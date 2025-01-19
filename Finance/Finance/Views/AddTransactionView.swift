import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TransactionStore
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var date = Date()
    @State private var type: TransactionType
    @State private var selectedCategory: Category?
    @State private var isRecurring = false
    @State private var recurringInterval: Transaction.RecurringInterval = .monthly
    @State private var showAlert = false
    
    init(type: TransactionType = .expense) {
        _type = State(initialValue: type)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Сумма") {
                    TextField("0", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Тип") {
                    Picker("Тип транзакции", selection: $type) {
                        Text("Расход").tag(TransactionType.expense)
                        Text("Доход").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("КАТЕГОРИЯ") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(store.categories.filter { $0.type == type }) { category in
                                CategoryButton(category: category, 
                                             isSelected: selectedCategory?.id == category.id) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 80)
                }
                
                Section("Детали") {
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                    TextField("Заметка", text: $note)
                }
                
                Section {
                    Toggle("Регулярная транзакция", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Интервал", selection: $recurringInterval) {
                            Text("Ежедневно").tag(Transaction.RecurringInterval.daily)
                            Text("Еженедельно").tag(Transaction.RecurringInterval.weekly)
                            Text("Ежемесячно").tag(Transaction.RecurringInterval.monthly)
                            Text("Ежегодно").tag(Transaction.RecurringInterval.yearly)
                        }
                    }
                }
            }
            .navigationTitle("Новая транзакция")
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() },
                trailing: Button("Сохранить", action: saveTransaction)
            )
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Пожалуйста, заполните все обязательные поля")
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountDouble = Double(amount),
              let category = selectedCategory else {
            showAlert = true
            return
        }
        
        let transaction = Transaction(
            amount: amountDouble,
            category: category,
            date: date,
            note: note,
            type: type,
            isRecurring: isRecurring,
            recurringInterval: isRecurring ? recurringInterval : nil
        )
        
        store.addTransaction(transaction)
        dismiss()
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.color).opacity(isSelected ? 1 : 0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : Color(hex: category.color))
                }
                
                Text(category.name)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }
            .frame(width: 70)
        }
    }
} 