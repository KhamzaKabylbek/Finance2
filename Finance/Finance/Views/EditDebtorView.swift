import SwiftUI

struct EditDebtorView: View {
    @Environment(\.dismiss) var dismiss
    let debtor: Debtor
    @ObservedObject var store: DebtorStore
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var amount: String
    @State private var currency: Settings.Currency
    @State private var note: String
    @State private var deadline: Date
    @State private var hasDeadline: Bool
    @State private var isPaid: Bool
    
    init(debtor: Debtor, store: DebtorStore) {
        self.debtor = debtor
        self.store = store
        _name = State(initialValue: debtor.name)
        _phoneNumber = State(initialValue: debtor.phoneNumber)
        _amount = State(initialValue: String(format: "%.2f", debtor.amount))
        _currency = State(initialValue: debtor.currency)
        _note = State(initialValue: debtor.note)
        _deadline = State(initialValue: debtor.deadline ?? Date())
        _hasDeadline = State(initialValue: debtor.deadline != nil)
        _isPaid = State(initialValue: debtor.isPaid)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Имя", text: $name)
                    TextField("Телефон", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Сумма")) {
                    HStack {
                        TextField("Сумма", text: $amount)
                            .keyboardType(.decimalPad)
                        
                        Picker("Валюта", selection: $currency) {
                            ForEach(Settings.Currency.allCases, id: \.self) { currency in
                                Text("\(currency.name) (\(currency.rawValue))")
                                    .tag(currency)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
                
                Section(header: Text("Дополнительно")) {
                    TextField("Заметка", text: $note)
                    Toggle("Указать срок", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Срок", selection: $deadline, displayedComponents: .date)
                    }
                    Toggle("Оплачено", isOn: $isPaid)
                }
            }
            .navigationTitle("Редактировать")
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() },
                trailing: Button("Сохранить") {
                    if let amount = Double(amount), !name.isEmpty {
                        var updatedDebtor = debtor
                        updatedDebtor.name = name
                        updatedDebtor.phoneNumber = phoneNumber
                        updatedDebtor.amount = amount
                        updatedDebtor.currency = currency
                        updatedDebtor.note = note
                        updatedDebtor.deadline = hasDeadline ? deadline : nil
                        updatedDebtor.isPaid = isPaid
                        store.updateDebtor(updatedDebtor)
                        dismiss()
                    }
                }
                .disabled(name.isEmpty || amount.isEmpty)
            )
        }
    }
}
