import SwiftUI

struct AddDebtorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: DebtorStore
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var amount = ""
    @State private var currency: Settings.Currency = .kzt
    @State private var note = ""
    @State private var deadline: Date = Date()
    @State private var hasDeadline = false
    
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
                            currency: currency,
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
