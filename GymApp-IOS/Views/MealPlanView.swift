import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject var userPresenter: UserPresenter
    @EnvironmentObject var mealPresenter: MealPresenter
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingAddMealView = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIsSuccess = true
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if mealPresenter.isFetchingMealPlan {
                        ProgressView("Loading meal plan...")
                            .padding()
                    } else if let error = mealPresenter.mealPlanError {
                        VStack {
                            Text("Error loading meal plan")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.bottom, 4)
                            
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                if let userId = userPresenter.user?.id {
                                    mealPresenter.fetchDailyMealPlan(userId: userId, forceRefresh: true)
                                }
                            }) {
                                Text("Try Again")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.top)
                        }
                        .padding()
                    } else if let mealPlan = mealPresenter.mealPlan {
                        ScrollView {
                            // Pull to refresh
                            RefreshControl(isRefreshing: $isRefreshing, coordinateSpaceName: "mealPlanRefresh") {
                                if let userId = userPresenter.user?.id {
                                    mealPresenter.fetchDailyMealPlan(userId: userId, forceRefresh: true)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        isRefreshing = false
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                // Last updated time
                                if let lastUpdate = mealPresenter.lastMealPlanFetchDate {
                                    HStack {
                                        Spacer()
                                        Text("Last updated: \(formatDate(lastUpdate))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // User Info Section
                                userInfoSection(userInfo: mealPlan.userInfo)
                                
                                // Daily Totals Section
                                dailyTotalsSection(totals: mealPlan.mealPlan.dailyTotals)
                                
                                // Meal Sections
                                mealSection(title: "Breakfast", section: mealPlan.mealPlan.breakfast, mealType: .breakfast)
                                mealSection(title: "Lunch", section: mealPlan.mealPlan.lunch, mealType: .lunch)
                                mealSection(title: "Dinner", section: mealPlan.mealPlan.dinner, mealType: .dinner)
                                mealSection(title: "Snacks", section: mealPlan.mealPlan.snacks, mealType: .snack)
                                
                                // Total Nutrition Section
                                totalNutritionSection(totals: mealPlan.totalNutrition)
                            }
                            .padding()
                        }
                        .coordinateSpace(name: "mealPlanRefresh")
                    } else {
                        VStack {
                            Text("No meal plan available")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            Text("Tap the button below to load your personalized meal plan")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                if let userId = userPresenter.user?.id {
                                    mealPresenter.fetchDailyMealPlan(userId: userId, forceRefresh: true)
                                }
                            }) {
                                Text("Load Meal Plan")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.top)
                        }
                        .padding()
                    }
                }
                
                // Toast message
                if showToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: toastIsSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(toastIsSuccess ? .green : .red)
                            Text(toastMessage)
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                            }
                        }
                    }
                }
            }
            .navigationTitle("Meal Plan")
            .onAppear {
                if let userId = userPresenter.user?.id {
                    mealPresenter.fetchDailyMealPlan(userId: userId)
                }
            }
            .sheet(isPresented: $showingAddMealView) {
                AddMealView(initialMealType: selectedMealType)
            }
        }
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Helper Views
    
    private func userInfoSection(userInfo: MealPlanResponse.UserInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Information")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    infoRow(label: "Gender", value: userInfo.gender)
                    infoRow(label: "Age", value: "\(userInfo.age) years")
                    infoRow(label: "Weight", value: "\(String(format: "%.1f", userInfo.weight)) kg")
                    infoRow(label: "Height", value: "\(String(format: "%.1f", userInfo.height)) cm")
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    infoRow(label: "BMI", value: "\(String(format: "%.1f", userInfo.bmi))")
                    infoRow(label: "Goal", value: userInfo.goal)
                    infoRow(label: "Location", value: "\(userInfo.city), \(userInfo.country)")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
        }
    }
    
    private func dailyTotalsSection(totals: MealPlanResponse.NutritionTotals) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended Daily Intake")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack(spacing: 12) {
                nutritionItem(label: "Calories", value: "\(totals.calories)", color: .red)
                nutritionItem(label: "Protein", value: "\(String(format: "%.1f", totals.protein))g", color: .blue)
                nutritionItem(label: "Fat", value: "\(String(format: "%.1f", totals.fat))g", color: .yellow)
                nutritionItem(label: "Carbs", value: "\(String(format: "%.1f", totals.carbs))g", color: .green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func nutritionItem(label: String, value: String, color: Color) -> some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func mealSection(title: String, section: MealPlanResponse.MealSection, mealType: MealType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(section.totals.calories) kcal")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 4)
            
            ForEach(section.foods) { food in
                foodRow(food: food, mealType: mealType)
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    // Clear any previously selected foods
                    mealPresenter.clearMeal()
                    
                    // Add all foods from this meal section
                    for food in section.foods {
                        mealPresenter.addFoodFromMealPlan(food)
                    }
                    
                    // Set the meal type and show the AddMealView
                    selectedMealType = mealType
                    showingAddMealView = true
                    
                    // Show toast
                    toastMessage = "Added \(title) foods to meal"
                    toastIsSuccess = true
                    withAnimation {
                        showToast = true
                    }
                }) {
                    Text("Add to Daily Intake")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func foodRow(food: MealPlanResponse.MealFood, mealType: MealType) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.subheadline)
                
                Text(food.quantity)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(food.calories) kcal")
                    .font(.subheadline)
                
                HStack(spacing: 8) {
                    Text("P: \(String(format: "%.1f", food.protein))g")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("F: \(String(format: "%.1f", food.fat))g")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("C: \(String(format: "%.1f", food.carbs))g")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Button(action: {
                // Clear any previously selected foods
                mealPresenter.clearMeal()
                
                // Add this food to the meal
                mealPresenter.addFoodFromMealPlan(food)
                
                // Set the meal type and show the AddMealView
                selectedMealType = mealType
                showingAddMealView = true
                
                // Show toast
                toastMessage = "Added \(food.name) to meal"
                toastIsSuccess = true
                withAnimation {
                    showToast = true
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
    
    private func totalNutritionSection(totals: MealPlanResponse.NutritionTotals) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Nutrition")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack(spacing: 12) {
                nutritionItem(label: "Calories", value: "\(totals.calories)", color: .red)
                nutritionItem(label: "Protein", value: "\(String(format: "%.1f", totals.protein))g", color: .blue)
                nutritionItem(label: "Fat", value: "\(String(format: "%.1f", totals.fat))g", color: .yellow)
                nutritionItem(label: "Carbs", value: "\(String(format: "%.1f", totals.carbs))g", color: .green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - RefreshControl

struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    let coordinateSpaceName: String
    let onRefresh: () -> Void
    
    @State private var refreshStarted: Bool = false
    @State private var pullDistance: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .named(coordinateSpaceName)).minY > 0 {
                ZStack(alignment: .center) {
                    if isRefreshing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 16, weight: .bold))
                            .rotationEffect(.degrees(self.pullDistance > 50 ? 180 : 0))
                            .animation(.easeInOut, value: self.pullDistance)
                    }
                }
                .frame(width: geometry.size.width)
                .offset(y: -geometry.frame(in: .named(coordinateSpaceName)).minY/2)
                .onChange(of: geometry.frame(in: .named(coordinateSpaceName)).minY) { newValue in
                    self.pullDistance = newValue
                    
                    if newValue > 100 && !refreshStarted && !isRefreshing {
                        refreshStarted = true
                        isRefreshing = true
                        onRefresh()
                    }
                    
                    if newValue <= 0 {
                        refreshStarted = false
                    }
                }
            }
        }
        .frame(height: 0)
    }
}

#Preview {
    MealPlanView()
        .environmentObject(UserPresenter())
        .environmentObject(MealPresenter())
} 