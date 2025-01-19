import SwiftUI

struct AddDebtorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: DebtorStore
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var amount = ""
    @State private var note = ""
    @State private var deadline: Date = Date()
    @State private var hasDeadline = false
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Имя", text: $name)
                TextField("Телефон", text: $phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Сумма", text: $amount)
                    .keyboardType(.decimalPad)
                TextField("Заметка", text: $note)
                
                Toggle("Указать срок", isOn: $hasDeadline)
                if hasDeadline {
                    DatePicker("Срок", selection: $deadline, displayedComponents: .date)
                }
            }
            .navigationTitle("Новый должник")
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() },
                trailing: Button("Добавить") {
                    if let amount = Double(amount), !name.isEmpty {
                        let debtor = Debtor(
                            name: name,
                            phoneNumber: phoneNumber,
                            amount: amount,
                            note: note,
                            deadline: hasDeadline ? deadline : nil
                        )
                        store.addDebtor(debtor)
                        dismiss()
                    }
                }
                .disabled(name.isEmpty || amount.isEmpty)
            )
        }
    }
}
