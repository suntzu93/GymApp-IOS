import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject var viewModel = DashboardViewModel()
    @State private var showingAddMealSheet = false
    @State private var selectedMealType = "Breakfast"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let user = userManager.currentUser {
                        // User info card
                        UserInfoCardView(user: user)
                        
                        // Nutrition summary
                        if let nutritionSummary = viewModel.nutritionSummary {
                            NutritionSummaryView(nutritionSummary: nutritionSummary)
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        
                        // Today's meals
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Today's Meals")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAddMealSheet = true
                                }) {
                                    Label("Add", systemImage: "plus.circle.fill")
                                }
                            }
                            
                            if viewModel.isLoadingMeals {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if viewModel.meals.isEmpty {
                                Text("No meals recorded today")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(viewModel.meals) { meal in
                                    MealCardView(meal: meal, onDelete: {
                                        viewModel.deleteMeal(mealId: meal.id)
                                    })
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        
                        // Food suggestions
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Food Suggestions")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.getSuggestions(userId: user.id)
                                }) {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }
                            }
                            
                            if viewModel.isLoadingSuggestions {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if viewModel.suggestions.isEmpty {
                                Text("No suggestions available")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(viewModel.suggestions) { suggestion in
                                    SuggestionCardView(suggestion: suggestion)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        userManager.logout()
                    }) {
                        Text("Logout")
                    }
                }
            }
            .sheet(isPresented: $showingAddMealSheet) {
                AddMealView(mealName: $selectedMealType, onAddMeal: { foodItems in
                    if let userId = userManager.currentUser?.id {
                        viewModel.addMeal(userId: userId, mealName: selectedMealType, foodItems: foodItems)
                    }
                    showingAddMealSheet = false
                })
            }
            .onAppear {
                if let userId = userManager.currentUser?.id {
                    viewModel.loadData(userId: userId)
                }
            }
            .refreshable {
                if let userId = userManager.currentUser?.id {
                    viewModel.loadData(userId: userId)
                }
            }
        }
    }
}

struct UserInfoCardView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hello, \(user.name)")
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading) {
                    Label("\(user.gender), \(user.age) years", systemImage: "person.fill")
                    Label("\(String(format: "%.1f", user.weight)) kg, \(String(format: "%.1f", user.height)) cm", systemImage: "scalemass.fill")
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Label(user.activityLevel, systemImage: "figure.run")
                    Label(user.goal, systemImage: "target")
                }
            }
            
            Text("\(user.city), \(user.country)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct NutritionSummaryView: View {
    let nutritionSummary: NutritionSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Nutrition")
                .font(.headline)
            
            HStack {
                NutrientProgressView(
                    title: "Calories",
                    consumed: nutritionSummary.consumed.calories ?? 0,
                    goal: nutritionSummary.goals.calories ?? 0,
                    unit: "kcal"
                )
                
                NutrientProgressView(
                    title: "Protein",
                    consumed: Int(nutritionSummary.consumed.protein ?? 0),
                    goal: Int(nutritionSummary.goals.protein ?? 0),
                    unit: "g"
                )
                
                NutrientProgressView(
                    title: "Fat",
                    consumed: Int(nutritionSummary.consumed.fat ?? 0),
                    goal: Int(nutritionSummary.goals.fat ?? 0),
                    unit: "g"
                )
                
                NutrientProgressView(
                    title: "Carbs",
                    consumed: Int(nutritionSummary.consumed.carbs ?? 0),
                    goal: Int(nutritionSummary.goals.carbs ?? 0),
                    unit: "g"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct NutrientProgressView: View {
    let title: String
    let consumed: Int
    let goal: Int
    let unit: String
    
    var progress: Double {
        if goal == 0 { return 0 }
        return min(Double(consumed) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 5)
                    .opacity(0.3)
                    .foregroundColor(Color.blue)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: progress)
                
                VStack {
                    Text("\(consumed)")
                        .font(.system(size: 12, weight: .bold))
                    Text(unit)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 60, height: 60)
            
            Text("\(consumed)/\(goal)")
                .font(.caption2)
        }
    }
}

struct MealCardView: View {
    let meal: Meal
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(meal.mealName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(meal.totalCalories) kcal")
                    .fontWeight(.semibold)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            if let items = meal.items, !items.isEmpty {
                ForEach(items, id: \.id) { item in
                    HStack {
                        Text("• \(item.quantity)g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(item.calories) kcal")
                            .font(.caption)
                    }
                }
            }
            
            HStack {
                Label("\(String(format: "%.1f", meal.totalProtein))g", systemImage: "p.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Label("\(String(format: "%.1f", meal.totalFat))g", systemImage: "f.circle.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Spacer()
                
                Label("\(String(format: "%.1f", meal.totalCarbs))g", systemImage: "c.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct SuggestionCardView: View {
    let suggestion: FoodSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(suggestion.suggestedFood)
                .font(.headline)
            
            HStack {
                if let calories = suggestion.calories {
                    Text("\(calories) kcal")
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text("Portion: \(Int(suggestion.portionSize))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let protein = suggestion.protein {
                    Label("\(String(format: "%.1f", protein))g", systemImage: "p.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if let fat = suggestion.fat {
                    Label("\(String(format: "%.1f", fat))g", systemImage: "f.circle.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                if let carbs = suggestion.carbs {
                    Label("\(String(format: "%.1f", carbs))g", systemImage: "c.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(UserManager())
    }
} 