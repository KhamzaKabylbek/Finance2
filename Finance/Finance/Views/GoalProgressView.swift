import SwiftUI
import Foundation

struct GoalProgressView: View {
    let goal: FinancialGoal
    @EnvironmentObject var store: TransactionStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    if let category = goal.category {
                        Text(category.name)
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.headline)
                        .foregroundColor(.accent)
                    
                    Text(formatDeadline())
                        .font(.caption)
                        .foregroundColor(goal.isOverdue ? .expenseRed : .secondaryText)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.cardBackground)
                        .cornerRadius(6)
                    
                    Rectangle()
                        .fill(goal.isOverdue ? Color.expenseRed : Color.accent)
                        .frame(width: geometry.size.width * goal.progress)
                        .cornerRadius(6)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text(store.formatAmount(goal.currentAmount))
                Spacer()
                Text(store.formatAmount(goal.targetAmount))
            }
            .font(.caption)
            .foregroundColor(.secondaryText)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .standardShadow()
    }
    
    private func formatDeadline() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "До \(formatter.string(from: goal.deadline))"
    }
} 