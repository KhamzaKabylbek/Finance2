import SwiftUI
import PhotosUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let attachedFile: URL?
    
    init(text: String, isUser: Bool, attachedFile: URL? = nil) {
        self.text = text
        self.isUser = isUser
        self.attachedFile = attachedFile
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
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var suggestions: [ChatSuggestion] = []
    private let geminiService = GeminiService()
    @EnvironmentObject var store: TransactionStore  // Добавляем доступ к TransactionStore
    
    var body: some View {
        Group {
            if isGeminiInitialized {
                NavigationView {
                    ZStack {
                        Color(.systemBackground)  // Изменено здесь
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
                                .onChange(of: messages.count) { _ in
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
                            
                            if !selectedImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(selectedImages.indices, id: \.self) { index in
                                            Image(uiImage: selectedImages[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    Button(action: {
                                                        selectedImages.remove(at: index)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.white)
                                                            .background(Color.black.opacity(0.5))
                                                            .clipShape(Circle())
                                                    }
                                                    .padding(4),
                                                    alignment: .topTrailing
                                                )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical, 8)
                            }
                            
                            HStack(spacing: 12) {
                                PhotosPicker(selection: $selectedItems,
                                           maxSelectionCount: 5,
                                           matching: .images) {
                                    Image(systemName: "paperclip")
                                        .font(.system(size: 20))
                                        .foregroundColor(.accent)
                                }
                                
                                TextField("Введите сообщение...", text: $newMessage)
                                    .padding(12)
                                    .background(Color.cardBackground)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.accent.opacity(0.2), lineWidth: 1)
                                    )
                                
                                Button(action: {
                                    Task {
                                        await sendMessage()
                                    }
                                }) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.accent)
                                }
                                .disabled(newMessage.isEmpty && selectedImages.isEmpty || isLoading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))  // Изменено здесь
                        }
                    }
                    .alert("Ошибка", isPresented: $showingAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(alertMessage)
                    }
                    .navigationTitle("AI Ассистент")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Закрыть") {
                                dismiss()
                            }
                        }
                    }
                }
            } else {
                ProgressView("Инициализация...")
                    .onAppear {
                        initializeServices()
                    }
            }
        }
        .onChange(of: selectedItems) { _ in
            Task {
                selectedImages.removeAll()
                for item in selectedItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImages.append(image)
                        }
                    }
                }
                selectedItems.removeAll()
            }
        }
        .onAppear {
            setupSuggestions()
        }
    }
    
    private var suggestionsView: some View {
        VStack(spacing: 8) { // Изменено с HStack на VStack
            ForEach(suggestions) { suggestion in
                Button(action: {
                    Task {
                        await suggestion.action()
                    }
                }) {
                    Text(suggestion.text)
                        .font(.system(size: 14, weight: .medium)) // Увеличен размер шрифта
                        .multilineTextAlignment(.center) // Добавлено выравнивание
                        .frame(maxWidth: .infinity) // Растягиваем на всю ширину
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12) // Изменена форма с Capsule на RoundedRectangle
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
                _ = try await geminiService.generateResponse(for: "test")
                await MainActor.run {
                    isGeminiInitialized = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Ошибка инициализации AI: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func sendMessage() async {
        guard !newMessage.isEmpty || !selectedImages.isEmpty else { return }
        guard isGeminiInitialized else {
            alertMessage = "Сервисы еще не инициализированы"
            showingAlert = true
            return
        }
        
        let messageText = newMessage
        
        await MainActor.run {
            messages.append(ChatMessage(text: messageText, isUser: true))
            newMessage = ""
            isLoading = true
        }
        
        do {
            let response = try await geminiService.generateResponse(for: messageText)
            
            if response.isEmpty {
                throw NSError(domain: "AIChatView", code: 2, 
                            userInfo: [NSLocalizedDescriptionKey: "Получен пустой ответ от сервиса"])
            }
            
            await MainActor.run {
                messages.append(ChatMessage(text: response, isUser: false))
                isLoading = false
            }
        } catch {
            await MainActor.run {
                messages.append(ChatMessage(
                    text: "Ошибка: \(error.localizedDescription)", 
                    isUser: false
                ))
                isLoading = false
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        
        if !selectedImages.isEmpty {
            await MainActor.run {
                // Здесь можно добавить логику для отправки изображений
                selectedImages.removeAll()
            }
        }
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
    
    private func analyzeExpenses() async {
        let fileURL = generateCSV()
        let csvData = try? String(contentsOf: fileURL, encoding: .utf8)
        
        guard let csvContent = csvData, !store.transactions.isEmpty else {
            await MainActor.run {
                messages.append(ChatMessage(text: "Нет данных для анализа. Добавьте транзакции.", isUser: false))
            }
            return
        }
        
        await MainActor.run {
            messages.append(ChatMessage(text: "Анализирую ваши транзакции...", isUser: false))
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
        6. Дать ответ в красивом виде
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
                messages.append(ChatMessage(text: response, isUser: false))
                isLoading = false
            }
        } catch {
            await MainActor.run {
                messages.append(ChatMessage(
                    text: "Ошибка анализа: \(error.localizedDescription)", 
                    isUser: false
                ))
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
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
                if let fileURL = message.attachedFile {
                    HStack {
                        Image(systemName: "doc")
                        Text(fileURL.lastPathComponent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accent.opacity(0.8))
                    )
                    .foregroundColor(.white)
                } else {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.accent)
                        )
                        .foregroundColor(.white)
                }
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accent)
            } else {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                    )
                    .foregroundColor(.primaryText)
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
}

struct ChatSuggestion: Identifiable {
    let id = UUID()
    let text: String
    let action: () async -> Void
}
