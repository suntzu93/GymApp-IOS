import SwiftUI
import UIKit

struct NutritionCard: View {
    let title: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let backgroundColor: Color
    
    init(
        title: String,
        calories: Int,
        protein: Double,
        fat: Double,
        carbs: Double,
        backgroundColor: Color = Color(UIColor.systemBackground)
    ) {
        self.title = title
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                NutrientItem(
                    label: "calories".localized,
                    value: "\(calories)",
                    unit: "kcal".localized,
                    color: .red
                )
                
                Spacer()
                
                NutrientItem(
                    label: "protein".localized,
                    value: String(format: "%.1f", protein),
                    unit: "g".localized,
                    color: .blue
                )
                
                Spacer()
                
                NutrientItem(
                    label: "fat".localized,
                    value: String(format: "%.1f", fat),
                    unit: "g".localized,
                    color: .yellow
                )
                
                Spacer()
                
                NutrientItem(
                    label: "carbs".localized,
                    value: String(format: "%.1f", carbs),
                    unit: "g".localized,
                    color: .green
                )
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct NutrientItem: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(color.opacity(0.8))
            }
        }
    }
}

struct NutritionCard_Previews: PreviewProvider {
    static var previews: some View {
        NutritionCard(
            title: "Daily Goal",
            calories: 2500,
            protein: 150,
            fat: 80,
            carbs: 300
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
