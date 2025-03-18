import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var authViewModel: AuthViewModel // Добавляем AuthViewModel

    @StateObject var goalStore: GoalStore
    @State private var selectedCurrency: Settings.Currency = .kzt
    @State private var showingAddGoal = false
    @State private var showingShareSheet = false
    @State private var showingLogoutAlert = false // Добавляем состояние для алерта
    @State private var pushNotificationsEnabled = false

    @State private var csvString: String = ""
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(goalStore: GoalStore) {
        _goalStore = StateObject(wrappedValue: goalStore)
    }
    
    private var incomeCategories: [Category] {
        store.categories.filter { $0.type == .income }
    }
    
    private func addGoal(_ goal: FinancialGoal) {
        goalStore.addGoal(goal)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Валюта
                Section("Валюта") {
                    Picker("Выберите валюту", selection: $selectedCurrency) {
                        ForEach(Settings.Currency.allCases, id: \.self) { currency in
                            HStack {
                                Text(currency.rawValue)
                                Text(currency.name)
                            }
                            .tag(currency)
                        }
                    }
                    .onChange(of: selectedCurrency) { oldValue, newValue in
                        store.updateCurrency(newValue)
                    }
                }

                Section("Уведомление") {
                    Toggle("Уведомление о финансовых целях", isOn: $pushNotificationsEnabled)
                }
                
                // Тема
                Section("Внешний вид") {
                    Toggle("Темная тема", isOn: $themeManager.isDarkMode)
                }
                
                // Финансовые цели
                Section(header: Text("Финансовые цели"), footer: Text("Нажмите +, чтобы добавить новую цель")) {
                    ForEach(store.settings.financialGoals) { goal in
                        GoalRow(goal: goal)
                    }
                    Button(action: { showingAddGoal = true }) {
                        Label("Добавить цель", systemImage: "plus")
                    }
                }
                
                // Экспорт данных
                Section("Экспорт") {
                    Button(action: prepareAndShareCSV) {
                        Label("Поделиться данными", systemImage: "square.and.arrow.up")
                    }
                }
                //
                
                // Добавляем новую секцию для выхода
                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Text("Выйти")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Уведомления") {
                    Toggle("Уведомления о достижении целей", isOn: $pushNotificationsEnabled)
                        .onChange(of: pushNotificationsEnabled) { isEnabled in
                            if isEnabled {
                                GoalNotificationManager.shared.requestPermission()
                            } else {
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }
                }
                
                // Добавляем кнопку для тестирования уведомлений
                Section {
                    Button("Test Notification") {
                        let testGoal = FinancialGoal(name: "Test Goal", targetAmount: 1000, currentAmount: 1000, deadline: Date())
                        GoalNotificationManager.shared.notifyGoalAchieved(for: testGoal)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            )
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [generateCSV()])
            }
            .alert("Выйти из аккаунта", isPresented: $showingLogoutAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Выйти", role: .destructive) {
                    authViewModel.logout()
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Вы уверены, что хотите выйти из аккаунта?")
            }
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onAppear {
            selectedCurrency = store.settings.currency
        }
    }
            

    
    //
    
    private func prepareAndShareCSV() {
        showingShareSheet = true
    }
    
    private func generateCSV() -> URL {
        var csvString = "Дата,Категория,Тип,Сумма,Заметка\n"
        
        for transaction in store.transactions {
            let row = "\(formatDate(transaction.date)),\(transaction.category.name),\(transaction.type),\(transaction.amount),\(transaction.note)\n"
            csvString.append(row)
        }
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("transactions.csv")
        try? csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct GoalRow: View {
    @EnvironmentObject var store: TransactionStore
    let goal: FinancialGoal
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddFundsSheet = false
    @State private var amountToAdd = ""
    @State private var pushNotificationsEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(goal.name)
                        .font(.headline)
                    Text("Срок: \(formatDate(goal.deadline))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Menu {
                    Button(action: { showingAddFundsSheet = true }) {
                        Label("Пополнить", systemImage: "plus.circle")
                    }
                    Button(action: { showingEditSheet = true }) {
                        Label("Изменить", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                Spacer()
                Text("\(store.formatAmount(goal.currentAmount)) / \(store.formatAmount(goal.targetAmount))")
                    .font(.caption)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(goal.progress >= 1 ? Color.green : Color.blue)
                        .frame(width: min(CGFloat(goal.progress) * geometry.size.width, geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            if goal.progress >= 1 {
                Text("Цель достигнута! 🎉")
                    .font(.caption)
                    .foregroundColor(.green)
                    .onAppear {
                        if pushNotificationsEnabled {
                            GoalNotificationManager.shared.notifyGoalAchieved(for: goal)
                        }
                    }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditGoalView(goal: goal)
        }
        .sheet(isPresented: $showingAddFundsSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Добавить средства")) {
                        TextField("Сумма", text: $amountToAdd)
                            .keyboardType(.decimalPad)
                    }
                    
                    Section(footer: Text("Средства будут добавлены к текущему прогрессу цели")) {
                        Button(action: addFunds) {
                            Text("Пополнить")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .navigationTitle("Пополнение цели")
                .navigationBarItems(
                    trailing: Button("Готово") {
                        showingAddFundsSheet = false
                    }
                )
            }
        }
        .alert("Удалить цель?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                store.deleteGoal(goal)
            }
        }
    }
    
    private func addFunds() {
        if let amount = Double(amountToAdd), amount > 0 {
            store.addFundsToGoal(goal, amount: amount)
            amountToAdd = ""
            showingAddFundsSheet = false
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct EditGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TransactionStore
    let goal: FinancialGoal
    
    @State private var name: String
    @State private var targetAmount: String
    @State private var currentAmount: String
    @State private var deadline: Date
    @State private var selectedCategory: Category?
    
    var incomeCategories: [Category] {
        store.categories.filter { $0.type == .income }
    }
    
    init(goal: FinancialGoal) {
        self.goal = goal
        _name = State(initialValue: goal.name)
        _targetAmount = State(initialValue: String(goal.targetAmount))
        _currentAmount = State(initialValue: String(goal.currentAmount))
        _deadline = State(initialValue: goal.deadline)
        _selectedCategory = State(initialValue: goal.category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Название цели", text: $name)
                TextField("Целевая сумма", text: $targetAmount)
                    .keyboardType(.decimalPad)
                TextField("Текущая сумма", text: $currentAmount)
                    .keyboardType(.decimalPad)
                DatePicker("Срок", selection: $deadline, displayedComponents: .date)
                
                Picker("Источник дохода", selection: $selectedCategory) {
                    Text("Без категории").tag(nil as Category?)
                    ForEach(incomeCategories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
            .navigationTitle("Изменить цель")
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() },
                trailing: Button("Сохранить") {
                    if let targetAmount = Double(targetAmount),
                       let currentAmount = Double(currentAmount),
                       !name.isEmpty {
                        let updatedGoal = FinancialGoal(
                            id: goal.id,
                            name: name,
                            targetAmount: targetAmount,
                            currentAmount: currentAmount,
                            deadline: deadline,
                            category: selectedCategory
                        )
                        store.updateGoal(updatedGoal)
                        dismiss()
                    }
                }
            )
        }
    }
}

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TransactionStore
    
    @State private var name = ""
    @State private var targetAmount = ""
    @State private var deadline = Date()
    @State private var selectedCategory: Category?
    @State private var autoSavePercentage = 10.0
    @State private var milestoneNotifications = true
    
    private var incomeCategories: [Category] {
        store.categories.filter { $0.type == .income }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название цели", text: $name)
                    TextField("Целевая сумма", text: $targetAmount)
                        .keyboardType(.decimalPad)
                    DatePicker("Срок", selection: $deadline, displayedComponents: .date)
                }
                
                Section(header: Text("Источник накопления")) {
                    Picker("Категория дохода", selection: $selectedCategory) {
                        Text("Без категории").tag(nil as Category?)
                        ForEach(incomeCategories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                    
                    if selectedCategory != nil {
                        VStack(alignment: .leading) {
                            Text("Откладывать от дохода: \(Int(autoSavePercentage))%")
                            Slider(value: $autoSavePercentage, in: 1...100, step: 1)
                        }
                    }
                }
                
                Section(header: Text("Уведомления")) {
                    Toggle("Уведомления о достижениях", isOn: $milestoneNotifications)
                }
            }
            .navigationTitle("Новая цель")
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() },
                trailing: Button("Сохранить") {
                    if let amount = Double(targetAmount), !name.isEmpty {
                        let goal = FinancialGoal(
                            name: name,
                            targetAmount: amount,
                            deadline: deadline,
                            category: selectedCategory,
                            autoSavePercentage: autoSavePercentage,
                            milestoneNotifications: milestoneNotifications
                        )
                        store.addGoal(goal)
                        
                        // Настраиваем уведомления
                        if milestoneNotifications {
                            NotificationManager.shared.scheduleDeadlineReminder(for: goal)
                            NotificationManager.shared.scheduleWeeklyProgressNotification(for: goal)
                        }
                        
                        dismiss()
                    }
                }
            )
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
