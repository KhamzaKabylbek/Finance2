import SwiftUI

struct DebtorsView: View {
    @StateObject private var debtorStore = DebtorStore()
    @State private var showingAddDebtor = false
    @State private var showingExport = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(debtorStore.debtors) { debtor in
                    DebtorRow(debtor: debtor, store: debtorStore)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Должники")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Закрыть") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { showingAddDebtor = true }) {
                        Image(systemName: "plus")
                    }
                    
                    Button(action: { showingExport = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddDebtor) {
            AddDebtorView(store: debtorStore)
        }
        .sheet(isPresented: $showingExport) {
            ShareSheet(items: [debtorStore.exportCSV()])
        }
    }
}

struct DebtorRow: View {
    let debtor: Debtor
    @ObservedObject var store: DebtorStore
    @State private var showingEdit = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Статус оплаты
                Circle()
                    .fill(debtor.isPaid ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                    .padding(.top, 6)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Имя и сумма
                    HStack {
                        Text(debtor.name)
                            .font(.headline)
                        Spacer()
                        Text(debtor.formattedAmount)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(debtor.isPaid ? .green : .red)
                    }
                    
                    // Телефон
                    if !debtor.phoneNumber.isEmpty {
                        HStack {
                            Image(systemName: "phone.circle.fill")
                                .foregroundColor(.gray)
                            Text(debtor.phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Заметка
                    if !debtor.note.isEmpty {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.gray)
                            Text(debtor.note)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Срок
                    if let deadline = debtor.deadline {
                        HStack {
                            Image(systemName: "calendar.circle.fill")
                                .foregroundColor(.gray)
                            Text(deadline.formatted(date: .long, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            )
        }
        .contextMenu {
            Button(action: {
                showingEdit = true
            }) {
                Label("Изменить", systemImage: "pencil")
            }
            
            Button(action: {
                var updatedDebtor = debtor
                updatedDebtor.isPaid.toggle()
                store.updateDebtor(updatedDebtor)
            }) {
                Label(debtor.isPaid ? "Отметить как неоплаченное" : "Отметить как оплаченное",
                      systemImage: debtor.isPaid ? "xmark.circle" : "checkmark.circle")
            }
            
            Button(role: .destructive, action: {
                store.deleteDebtor(debtor)
            }) {
                Label("Удалить", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditDebtorView(debtor: debtor, store: store)
        }
    }
}
