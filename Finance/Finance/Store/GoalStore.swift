import Foundation
import SwiftUI

class GoalStore: ObservableObject {
    @Published var goals: [FinancialGoal] = []
    private let saveKey = "financial_goals"
    
    init() {
        loadGoals()
    }
    
    func addGoal(_ goal: FinancialGoal) {
        goals.append(goal)
        saveGoals()
    }
    
    func updateGoal(_ goal: FinancialGoal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
        }
    }
    
    func deleteGoal(_ goal: FinancialGoal) {
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }
    
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([FinancialGoal].self, from: data) {
                goals = decoded
            }
        }
    }
    
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
} 