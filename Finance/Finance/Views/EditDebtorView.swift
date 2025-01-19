import SwiftUI

struct EditDebtorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: DebtorStore
    let debtor: Debtor
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var amount: String
    @State private var note: String
    @State private var deadline: Date
    @State private var hasDeadline: Bool
    @State private var isPaid: Bool
    
    init(debtor: Debtor, store: DebtorStore) {
        self.debtor = debtor
        self.store = store
        _name = State(initialValue: debtor.name)
        _phoneNumber = State(initialValue: debtor.phoneNumber)
        _amount = State(initialValue: String(debtor.amount))
        _note = State(initialValue: debtor.note)
        _deadline = State(initialValue: debtor.deadline ?? Date())
        _hasDeadline = State(initialValue: debtor.deadline != nil)
        _isPaid = State(initialValue: debtor.isPaid)
    }
    
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
                
                Toggle("Оплачено", isOn: $isPaid)
            }
            .navigationTitle("Изменить должника")
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() },
                trailing: Button("Сохранить") {
                    if let amount = Double(amount), !name.isEmpty {
                        let updatedDebtor = Debtor(
                            id: debtor.id,
                            name: name,
                            phoneNumber: phoneNumber,
                            amount: amount,
                            note: note,
                            deadline: hasDeadline ? deadline : nil,
                            isPaid: isPaid
                        )
                        store.updateDebtor(updatedDebtor)
                        dismiss()
                    }
                }
                .disabled(name.isEmpty || amount.isEmpty)
            )
        }
    }
}
