import SwiftUI

struct DebtorsView: View {
    @StateObject private var debtorStore = DebtorStore()
    @State private var showingAddDebtor = false
    @State private var showingExport = false
    
    var body: some View {
        List {
            ForEach(debtorStore.debtors) { debtor in
                DebtorRow(debtor: debtor, store: debtorStore)
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    debtorStore.deleteDebtor(debtorStore.debtors[index])
                }
            }
        }
        .navigationTitle("Должники")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddDebtor = true }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingExport = true }) {
                    Image(systemName: "square.and.arrow.up")
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
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(debtor.name)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f", debtor.amount))
                    .foregroundColor(debtor.isPaid ? .green : .red)
            }
            
            if !debtor.phoneNumber.isEmpty {
                Text(debtor.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !debtor.note.isEmpty {
                Text(debtor.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let deadline = debtor.deadline {
                Text("Срок: \(deadline.formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                store.deleteDebtor(debtor)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
            
            Button {
                showingEdit = true
            } label: {
                Label("Изменить", systemImage: "pencil")
            }
            .tint(.blue)
            
            Button {
                var updatedDebtor = debtor
                updatedDebtor.isPaid.toggle()
                store.updateDebtor(updatedDebtor)
            } label: {
                Label(debtor.isPaid ? "Не погашено" : "Погашено",
                      systemImage: debtor.isPaid ? "xmark.circle" : "checkmark.circle")
            }
            .tint(debtor.isPaid ? .red : .green)
        }
        .sheet(isPresented: $showingEdit) {
            EditDebtorView(debtor: debtor, store: store)
        }
    }
}
