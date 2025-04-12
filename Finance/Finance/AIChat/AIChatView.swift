import SwiftUI
import PhotosUI

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(text: String, isUser: Bool) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
    }
}

struct AIChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isGeminiInitialized = false
    @State private var suggestions: [ChatSuggestion] = []
    private let geminiService = GeminiService()
    @EnvironmentObject var store: TransactionStore
    
    private let messagesKey = "chatHistory"
    
    var body: some View {
        Group {
            if isGeminiInitialized {
                NavigationView {
                    ZStack {
                        Color(.systemBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(spacing: 16) {
                                        ForEach(messages) { message in
                                            MessageBubble(message: message)
                                                .transition(.asymmetric(
                                                    insertion: .scale.combined(with: .opacity),
                                                    removal: .opacity))
                                                .id(message.id)
                                        }
                                        if isLoading {
                                            ProgressView()
                                                .padding()
                                        }
                                    }
                                    .padding()
                                }
                                .onChange(of: messages.count) { oldValue, newValue in
                                    withAnimation {
                                        if let lastMessage = messages.last {
                                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                            
                            if messages.isEmpty {
                                suggestionsView
                            }
                            
                            HStack(spacing: 12) {
                                TextField("Введите сообщение...", text: $newMessage)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .stroke(Color.accent.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .disabled(isLoading)
                                
                                Button {
                                    Task {
                                        await sendMessage()
                                    }
                                } label: {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 46, height: 46)
                                        .background(
                                            Circle()
                                                .fill(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? 
                                                    Color.accent.opacity(0.5) : 
                                                    Color.accent)
                                        )
                                        .shadow(color: Color.accent.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                        }
                    }
                    .alert("Ошибка", isPresented: $showingAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(alertMessage)
                    }
                    .navigationBarTitle("Чат с ИИ", displayMode: .inline)
                    .navigationBarItems(
                        leading: Button(action: dismiss.callAsFunction) {
                            Image(systemName: "xmark")
                                .foregroundColor(.primary)
                        },
                        trailing: Button(action: clearHistory) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    )
                    .onAppear {
                        loadMessages() // Load messages when the view appears
                        setupSuggestions()
                    }
                }
            } else {
                ProgressView("Инициализация...")
                    .onAppear {
                        initializeServices()
                    }
            }
        }
    }
    
    private var suggestionsView: some View {
        VStack(spacing: 8) {
            ForEach(suggestions) { suggestion in
                Button(action: {
                    Task {
                        await suggestion.action()
                    }
                }) {
                    Text(suggestion.text)
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accent.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.accent.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.accent)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func initializeServices() {
        Task {
            do {
                // Проверяем соединение простым тестовым запросом
                let testResponse = try await geminiService.generateResponse(for: "test")
                if !testResponse.isEmpty {
                    await MainActor.run {
                        isGeminiInitialized = true
                        loadMessages() // Загружаем историю при инициализации
                    }
                }
            } catch {
                print("Error initializing Gemini: \(error)")
                await MainActor.run {
                    showingAlert = true
                    alertMessage = "Ошибка инициализации: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: messagesKey)
        }
    }
    
    private func loadMessages() {
        if let data = UserDefaults.standard.data(forKey: messagesKey),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = decoded
        }
    }
    
    private func addMessage(_ text: String, isUser: Bool) {
        let message = ChatMessage(text: text, isUser: isUser)
        messages.append(message)
        saveMessages() // Save messages after adding a new one
    }
    
    private func clearHistory() {
        messages.removeAll()
        saveMessages() // Save empty state to clear history
    }
    
    private func sendMessage() async {
        guard !newMessage.isEmpty else { return }
        guard isGeminiInitialized else {
            alertMessage = "Сервисы еще не инициализированы"
            showingAlert = true
            return
        }

        let messageText = newMessage
        let transactionsCSV = generateCSVContent() // Generate CSV content for all transactions
        let currentBalance = store.formatAmount(store.totalBalance) // Get current balance
        let totalIncome = store.transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount } // Calculate total income

        let fullPrompt = """
        Вот мои данные:
        - Текущий баланс: \(currentBalance)
        - Общий доход: \(store.formatAmount(totalIncome))
        
        Вот мои транзакции:
        \(transactionsCSV)
        
        Теперь ответь на мой запрос:
        \(messageText)
        """

        await MainActor.run {
            addMessage(messageText, isUser: true) // Save user message
            newMessage = ""
            isLoading = true
        }

        do {
            let response = try await geminiService.generateResponse(for: fullPrompt)

            if response.isEmpty {
                throw NSError(domain: "AIChatView", code: 2, 
                            userInfo: [NSLocalizedDescriptionKey: "Получен пустой ответ от сервиса"])
            }

            await MainActor.run {
                addMessage(response, isUser: false) // Save AI response
                isLoading = false
            }
        } catch {
            await MainActor.run {
                addMessage("Ошибка: \(error.localizedDescription)", isUser: false)
                isLoading = false
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }

    private func generateCSVContent() -> String {
        var csvString = "Дата,Категория,Тип,Сумма,Заметка\n"
        
        for transaction in store.transactions {
            let row = "\(formatDate(transaction.date)),\(transaction.category.name),\(transaction.type.rawValue),\(transaction.amount),\"\(transaction.note)\"\n"
            csvString.append(row)
        }
        
        return csvString
    }
    
    private func analyzeExpenses() async {
        let fileURL = generateCSV()
        let csvData = try? String(contentsOf: fileURL, encoding: .utf8)
        
        guard let csvContent = csvData, !store.transactions.isEmpty else {
            await MainActor.run {
                addMessage("Нет данных для анализа. Добавьте транзакции.", isUser: false)
            }
            return
        }
        
        await MainActor.run {
            addMessage("Анализирую ваши транзакции...", isUser: false)
        }
        
        let prompt = """
        Проанализируй следующие транзакции:
        
        \(csvContent)
        
        Пожалуйста, предоставь детальный анализ:
        1. Основные категории расходов и их процентное соотношение
        2. Самые крупные транзакции и их обоснованность
        3. Рекомендации по оптимизации расходов
        4. Анализ доходов и их источников
        5. Общие тенденции и шаблоны трат
        6. Дай ответ в красивом виде
        7. Не писать валюту в суммах
        8. Не писать много текста
        
        Дай конкретные советы по улучшению финансового поведения.
        """
        
        do {
            let response = try await geminiService.generateResponse(for: prompt)
            
            if response.isEmpty {
                throw NSError(domain: "AIChatView", code: 2, 
                            userInfo: [NSLocalizedDescriptionKey: "Получен пустой ответ от сервиса"])
            }
            
            await MainActor.run {
                addMessage(response, isUser: false)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                addMessage("Ошибка анализа: \(error.localizedDescription)", isUser: false)
                isLoading = false
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }

    private func generateCSV() -> URL {
        var csvString = "Дата,Категория,Тип,Сумма,Заметка\n"
        
        for transaction in store.transactions {
            let row = "\(formatDate(transaction.date)),\(transaction.category.name),\(transaction.type.rawValue),\(transaction.amount),\"\(transaction.note)\"\n"
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
    
    private func sendMessage(withText text: String) async {
        await MainActor.run {
            newMessage = text
        }
        await sendMessage()
    }

    private func setupSuggestions() {
        suggestions = [
            ChatSuggestion(text: "📊 Анализ расходов и доходов", action: {
                await analyzeExpenses()
            }),
            ChatSuggestion(text: "💡 Советы по экономии денег", action: {
                await sendMessage(withText: "Дай мне общие советы по экономии денег")
            }),
            ChatSuggestion(text: "📈 Как ставить финансовые цели", action: {
                await sendMessage(withText: "Как правильно ставить финансовые цели?")
            }),
            ChatSuggestion(text: "💰 Как составить бюджет", action: {
                await sendMessage(withText: "Как составить эффективный бюджет?")
            })
        ]
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            }
            
            Text(message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(message.isUser ? .white : .primary)
                .background(message.isUser ? Color.accent : Color(.systemGray6))
                .cornerRadius(20)
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct ChatSuggestion: Identifiable {
    let id = UUID()
    let text: String
    let action: () async -> Void
}
