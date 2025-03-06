import SwiftUI
import UIKit

struct FoodItemRow: View {
    let food: Food
    var showActions: Bool = true
    var onAddToFavorites: (() -> Void)?
    var onAddToMeal: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(food.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            if let description = food.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 16) {
                NutrientBadge(
                    value: "\(food.calories)",
                    unit: "kcal".localized,
                    color: .red
                )
                
                NutrientBadge(
                    value: String(format: "%.1f", food.protein),
                    unit: "g".localized + " " + "protein".localized,
                    color: .blue
                )
                
                NutrientBadge(
                    value: String(format: "%.1f", food.fat),
                    unit: "g".localized + " " + "fat".localized,
                    color: .yellow
                )
                
                NutrientBadge(
                    value: String(format: "%.1f", food.carbs),
                    unit: "g".localized + " " + "carbs".localized,
                    color: .green
                )
            }
            
            if showActions {
                HStack {
                    if let addToFavorites = onAddToFavorites {
                        Button(action: addToFavorites) {
                            Image(systemName: food.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(food.isLiked ? .red : .gray)
                        }
                    }
                    
                    if let onAddToMeal = onAddToMeal {
                        Spacer()
                        
                        Button(action: onAddToMeal) {
                            Label("add_to_meal".localized, systemImage: "plus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct NutrientBadge: View {
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(color.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FoodItemRow_Previews: PreviewProvider {
    static var previews: some View {
        FoodItemRow(
            food: Food(
                id: "1",
                name: "Phở Bò",
                description: "Vietnamese beef noodle soup",
                calories: 350,
                protein: 25,
                fat: 10,
                carbs: 45,
                country: "Vietnam",
                city: "Hanoi"
            ),
            onAddToFavorites: {},
            onAddToMeal: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
