import SwiftUI
import Charts // Добавляем импорт Charts для графиков

struct AnalyticsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TransactionStore
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var selectedChart: ChartType = .pie
    @State private var showingFilters = false
    
    enum AnalyticsPeriod: String, CaseIterable {
        case week = "Неделя"
        case month = "Месяц"
        case year = "Год"
    }
    
    enum ChartType: String, CaseIterable {
        case pie = "Круговой"
        case bar = "Столбчатый"
        case line = "Линейный"
    }
    
    var filteredTransactions: [Transaction] {
        store.transactions.filter { transaction in
            switch selectedPeriod {
            case .week:
                return Calendar.current.isDate(transaction.date, equalTo: Date(), toGranularity: .weekOfYear)
            case .month:
                return Calendar.current.isDate(transaction.date, equalTo: Date(), toGranularity: .month)
            case .year:
                return Calendar.current.isDate(transaction.date, equalTo: Date(), toGranularity: .year)
            }
        }
    }
    
    var expensesByCategory: [(Category, Double)] {
        let expenses = filteredTransactions.filter { $0.type == .expense }
        var categoryTotals: [Category: Double] = [:]
        
        for expense in expenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        return categoryTotals.sorted { $0.value > $1.value }
    }
    
    var totalIncome: Double {
        filteredTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Double {
        filteredTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var averageExpense: Double {
        let expenses = filteredTransactions.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return 0 }
        return expenses.reduce(0) { $0 + $1.amount } / Double(expenses.count)
    }
    
    var categoryAnalysis: CategoryAnalysis {
        let expenses = filteredTransactions.filter { $0.type == .expense }
        var categoryTotals: [Category: (amount: Double, count: Int)] = [:]
        
        for expense in expenses {
            let current = categoryTotals[expense.category] ?? (0, 0)
            categoryTotals[expense.category] = (
                amount: current.amount + expense.amount,
                count: current.count + 1
            )
        }
        
        let sorted = categoryTotals.map { (category: $0.key, amount: $0.value.amount, count: $0.value.count) }
        let mostExpensive = sorted.sorted { $0.amount > $1.amount }.prefix(3)
        let leastUsed = sorted.sorted { $0.count < $1.count }.prefix(3)
        
        return CategoryAnalysis(
            mostExpensive: Array(mostExpensive),
            leastUsed: Array(leastUsed)
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Период и тип графика
                    HStack {
                        Picker("Период", selection: $selectedPeriod) {
                            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Button(action: { showingFilters.toggle() }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Общая статистика
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Всего доходов",
                                value: totalIncome,
                                color: .green,
                                icon: "arrow.up.circle.fill"
                            )
                            StatCard(
                                title: "Всего расходов",
                                value: totalExpenses,
                                color: .red,
                                icon: "arrow.down.circle.fill"
                            )
                        }
                        
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Баланс",
                                value: totalIncome - totalExpenses,
                                color: .blue,
                                icon: "banknote"
                            )
                            
                            StatCard(
                                title: "Средняя затрата",
                                value: averageExpense,
                                color: .orange,
                                icon: "chart.bar.fill"
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Прогноз
                    if selectedPeriod == .month {
                        ForecastView(transactions: filteredTransactions)
                            .padding(.horizontal)
                    }
                    
                    // Графики
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Тип графика", selection: $selectedChart) {
                            ForEach(ChartType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if expensesByCategory.isEmpty {
                            // Показываем сообщение, когда нет данных
                            VStack(spacing: 8) {
                                Image(systemName: "chart.pie")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("Нет данных для отображения")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Добавьте несколько транзакций")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            switch selectedChart {
                            case .pie:
                                PieChartView(data: expensesByCategory)
                                    .frame(height: 300)
                            case .bar:
                                BarChartView(data: expensesByCategory)
                                    .frame(height: 300)
                            case .line:
                                LineChartView(transactions: filteredTransactions)
                                    .frame(height: 300)
                            }
                        }
                    }
                    
                    // Добавляем секцию анализа категорий
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Анализ категорий")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if categoryAnalysis.mostExpensive.isEmpty {
                            // Показываем сообщение, когда нет данных
                            VStack(spacing: 8) {
                                Image(systemName: "chart.pie")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("Нет данных для анализа")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Добавьте несколько транзакций")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        } else {
                            // Самые затратные категории
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Самые затратные категории")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                ForEach(categoryAnalysis.mostExpensive, id: \.category.id) { item in
                                    CategoryAnalysisRow(
                                        category: item.category,
                                        mainValue: item.amount,
                                        secondaryValue: "\(item.count) транз.",
                                        color: .red
                                    )
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Наименее используемые категории
                            if !categoryAnalysis.leastUsed.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Редко используемые категории")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    ForEach(categoryAnalysis.leastUsed, id: \.category.id) { item in
                                        CategoryAnalysisRow(
                                            category: item.category,
                                            mainValue: item.amount,
                                            secondaryValue: "\(item.count) транз.",
                                            color: .orange
                                        )
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Аналитика")
            .navigationBarItems(
                leading: Button("Закрыть") { dismiss() }
            )
            .sheet(isPresented: $showingFilters) {
                FilterView()
            }
        }
    }
}

struct StatCard: View {
    @EnvironmentObject var store: TransactionStore
    let title: String
    let value: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(store.formatAmount(value))
                .font(.headline)
                .foregroundColor(color)
            
            LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)], 
                          startPoint: .leading,
                          endPoint: .trailing)
                .frame(height: 4)
                .cornerRadius(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PieChartView: View {
    let data: [(Category, Double)]
    
    var body: some View {
        Chart {
            ForEach(data, id: \.0.id) { item in
                SectorMark(
                    angle: .value("Сумма", item.1),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(Color(hex: item.0.color))
            }
        }
        .padding()
    }
}

struct BarChartView: View {
    let data: [(Category, Double)]
    
    var body: some View {
        Chart {
            ForEach(data, id: \.0.id) { item in
                BarMark(
                    x: .value("Категория", item.0.name),
                    y: .value("Сумма", item.1)
                )
                .foregroundStyle(Color(hex: item.0.color))
            }
        }
        .padding()
    }
}

struct LineChartView: View {
    let transactions: [Transaction]
    
    var dailyTotals: [(Date, Double)] {
        let calendar = Calendar.current
        var totals: [Date: Double] = [:]
        
        for transaction in transactions {
            let day = calendar.startOfDay(for: transaction.date)
            totals[day, default: 0] += transaction.amount
        }
        
        return totals.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        if dailyTotals.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))
                Text("Нет данных для графика")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        } else {
            Chart {
                ForEach(dailyTotals, id: \.0) { item in
                    LineMark(
                        x: .value("Дата", item.0),
                        y: .value("Сумма", item.1)
                    )
                    .foregroundStyle(.blue)
                    
                    PointMark(
                        x: .value("Дата", item.0),
                        y: .value("Сумма", item.1)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .padding()
        }
    }
}

struct ForecastView: View {
    @EnvironmentObject var store: TransactionStore
    let transactions: [Transaction]
    
    var predictedExpense: Double {
        let expenses = transactions.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return 0 }
        
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        return totalExpense / Double(expenses.count) * 30
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Прогноз расходов на месяц")
                .font(.headline)
            Text(store.formatAmount(predictedExpense))
                .font(.title2)
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedCategories: Set<Category> = []
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Период") {
                    DatePicker("От", selection: $startDate, displayedComponents: .date)
                    DatePicker("До", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Сумма") {
                    TextField("Минимальная", text: $minAmount)
                        .keyboardType(.decimalPad)
                    TextField("Максимальная", text: $maxAmount)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() },
                trailing: Button("Применить") { dismiss() }
            )
        }
    }
}

// Добавляем структуры для анализа
struct CategoryAnalysis {
    let mostExpensive: [(category: Category, amount: Double, count: Int)]
    let leastUsed: [(category: Category, amount: Double, count: Int)]
}

struct CategoryAnalysisRow: View {
    @EnvironmentObject var store: TransactionStore
    let category: Category
    let mainValue: Double
    let secondaryValue: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(Color(hex: category.color))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.subheadline)
                Text(secondaryValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(store.formatAmount(mainValue))
                .font(.subheadline)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
} 