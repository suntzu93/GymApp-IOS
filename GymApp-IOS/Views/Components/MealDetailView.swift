import SwiftUI

struct MealDetailView: View {
    @EnvironmentObject var mealPresenter: MealPresenter
    @Environment(\.presentationMode) var presentationMode
    
    let mealId: String
    let userId: String
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if mealPresenter.isFetchingMealDetail {
                        LoadingView()
                    } else if let error = mealPresenter.mealDetailError {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Error loading meal details")
                                .font(.headline)
                            
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Try Again") {
                                mealPresenter.getMealDetails(mealId: mealId, userId: userId)
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    } else if let meal = mealPresenter.selectedMealDetail {
                        // Meal Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(meal.mealName)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(formatDate(meal.createdAt))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            // Nutrition Summary
                            HStack(spacing: 20) {
                                NutritionSummaryItem(label: "Calories", value: "\(meal.totalCalories) kcal")
                                NutritionSummaryItem(label: "Protein", value: String(format: "%.1f g", meal.totalProtein))
                                NutritionSummaryItem(label: "Fat", value: String(format: "%.1f g", meal.totalFat))
                                NutritionSummaryItem(label: "Carbs", value: String(format: "%.1f g", meal.totalCarbs))
                            }
                            .padding(.vertical)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Food Items
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Food Items")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if meal.items.isEmpty {
                                Text("No food items in this meal")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(meal.items) { item in
                                    FoodItemDetailRow(item: item)
                                }
                            }
                        }
                        
                        // Delete Button
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Meal")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                        .alert(isPresented: $showDeleteConfirmation) {
                            Alert(
                                title: Text("Delete Meal"),
                                message: Text("Are you sure you want to delete this meal? This action cannot be undone."),
                                primaryButton: .destructive(Text("Delete")) {
                                    mealPresenter.deleteMeal(mealId: mealId, userId: userId)
                                    presentationMode.wrappedValue.dismiss()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    } else {
                        Text("No meal details available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            
            if mealPresenter.showToast {
                ToastView(
                    message: mealPresenter.toastMessage,
                    isSuccess: mealPresenter.toastIsSuccess,
                    onDismiss: {
                        mealPresenter.showToast = false
                    }
                )
                .onAppear {
                    // Auto-dismiss the toast after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        mealPresenter.showToast = false
                    }
                }
            }
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            mealPresenter.getMealDetails(mealId: mealId, userId: userId)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Format: "2025-03-07T14:40:44"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

struct NutritionSummaryItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FoodItemDetailRow: View {
    let item: MealDetailResponse.MealItemDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.foodName)
                        .font(.headline)
                    
                    Text("\(Int(item.quantity))g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(item.calories) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                NutrientInfo(label: "Protein", value: String(format: "%.1fg", item.protein))
                NutrientInfo(label: "Fat", value: String(format: "%.1fg", item.fat))
                NutrientInfo(label: "Carbs", value: String(format: "%.1fg", item.carbs))
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

struct NutrientInfo: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
} 