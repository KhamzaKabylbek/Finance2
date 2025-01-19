import Foundation

class DebtorStore: ObservableObject {
    @Published var debtors: [Debtor] = []
    
    init() {
        loadDebtors()
    }
    
    private func loadDebtors() {
        if let data = UserDefaults.standard.data(forKey: "debtors") {
            if let decoded = try? JSONDecoder().decode([Debtor].self, from: data) {
                debtors = decoded
                return
            }
        }
        debtors = []
    }
    
    private func saveDebtors() {
        if let encoded = try? JSONEncoder().encode(debtors) {
            UserDefaults.standard.set(encoded, forKey: "debtors")
        }
    }
    
    func addDebtor(_ debtor: Debtor) {
        debtors.append(debtor)
        saveDebtors()
    }
    
    func updateDebtor(_ debtor: Debtor) {
        if let index = debtors.firstIndex(where: { $0.id == debtor.id }) {
            debtors[index] = debtor
            saveDebtors()
        }
    }
    
    func deleteDebtor(_ debtor: Debtor) {
        debtors.removeAll { $0.id == debtor.id }
        saveDebtors()
    }
    
    func exportCSV() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        var csv = "Имя,Телефон,Сумма,Заметка,Срок,Статус\n"
        for debtor in debtors {
            let deadline = debtor.deadline.map { dateFormatter.string(from: $0) } ?? ""
            let status = debtor.isPaid ? "Погашен" : "Не погашен"
            csv += "\(debtor.name),\(debtor.phoneNumber),\(debtor.amount),\(debtor.note),\(deadline),\(status)\n"
        }
        return csv
    }
}
