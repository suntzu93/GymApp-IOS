import SwiftUI
import UIKit

struct DailyNutritionView: View {
    @EnvironmentObject var userPresenter: UserPresenter
    @EnvironmentObject var mealPresenter: MealPresenter
    @State private var showingAddMealSheet = false
    @State private var showingSuggestionsSheet = false
    
    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            if let user = userPresenter.user {
                                // Daily Goal Card
                                NutritionCard(
                                    title: "daily_goal".localized,
                                    calories: user.dailyCalories ?? 0,
                                    protein: user.dailyProtein ?? 0,
                                    fat: user.dailyFat ?? 0,
                                    carbs: user.dailyCarbs ?? 0,
                                    backgroundColor: Color(uiColor: .systemBackground)
                                )
                                
                                // Consumed Card
                                NutritionCard(
                                    title: "consumed".localized,
                                    calories: mealPresenter.dailyNutrition.consumedCalories,
                                    protein: mealPresenter.dailyNutrition.consumedProtein,
                                    fat: mealPresenter.dailyNutrition.consumedFat,
                                    carbs: mealPresenter.dailyNutrition.consumedCarbs,
                                    backgroundColor: Color(uiColor: .secondarySystemBackground)
                                )
                                
                                // Remaining Card
                                NutritionCard(
                                    title: "remaining".localized,
                                    calories: (user.dailyCalories ?? 0) - mealPresenter.dailyNutrition.consumedCalories,
                                    protein: (user.dailyProtein ?? 0) - mealPresenter.dailyNutrition.consumedProtein,
                                    fat: (user.dailyFat ?? 0) - mealPresenter.dailyNutrition.consumedFat,
                                    carbs: (user.dailyCarbs ?? 0) - mealPresenter.dailyNutrition.consumedCarbs,
                                    backgroundColor: Color(uiColor: .tertiarySystemBackground)
                                )
                                
                                // Action Buttons
                                HStack(spacing: 20) {
                                    Button(action: {
                                        showingAddMealSheet = true
                                    }) {
                                        VStack {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 30))
                                            Text("add_meal".localized)
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    
                                    Button(action: {
                                        showingSuggestionsSheet = true
                                        if let userId = userPresenter.user?.id {
                                            mealPresenter.fetchMealHistory(userId: userId)
                                        }
                                    }) {
                                        VStack {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 30))
                                            Text("suggest_next_meal".localized)
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Today's Meals
                                if !mealPresenter.mealHistory.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Today's Meals")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(todayMeals) { meal in
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(meal.mealName)
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                    
                                                    Text(formatTime(from: meal.createdAt))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Text("\(meal.totalCalories) kcal")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding()
                                            .background(Color(uiColor: .systemBackground))
                                            .cornerRadius(10)
                                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    print("Context menu: Delete meal with ID: \(meal.mealId)")
                                                    if let userId = userPresenter.user?.id {
                                                        mealPresenter.deleteMeal(mealId: meal.mealId, userId: userId)
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) {
                                                    print("Swipe action: Delete meal with ID: \(meal.mealId)")
                                                    if let userId = userPresenter.user?.id {
                                                        mealPresenter.deleteMeal(mealId: meal.mealId, userId: userId)
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                                .tint(.red)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            } else {
                                EmptyStateView(
                                    title: "No Data Available",
                                    message: "Your nutrition information will appear here once you complete your profile.",
                                    systemImage: "person.crop.circle.badge.exclamationmark"
                                )
                            }
                        }
                        .padding()
                    }
                    
                    if mealPresenter.isLoading || userPresenter.isLoading {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                        
                        LoadingView()
                    }
                }
                .navigationTitle("daily_nutrition_title".localized)
                .onAppear {
                    if let userId = userPresenter.user?.id {
                        mealPresenter.fetchMealHistory(userId: userId)
                        // Manually refresh daily nutrition
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            mealPresenter.refreshDailyNutrition()
                        }
                    }
                }
                .sheet(isPresented: $showingAddMealSheet) {
                    AddMealView()
                }
                .sheet(isPresented: $showingSuggestionsSheet) {
                    SuggestionsView()
                }
                .alert(item: Binding<AlertItem?>(
                    get: { mealPresenter.error != nil ? AlertItem(message: mealPresenter.error!) : nil },
                    set: { _ in mealPresenter.error = nil }
                )) { alert in
                    Alert(
                        title: Text("error".localized),
                        message: Text(alert.message),
                        dismissButton: .default(Text("ok".localized))
                    )
                }
            }
            
            // Toast overlay at the ZStack level (outside NavigationView)
            if mealPresenter.showToast {
                VStack {
                    ToastView(
                        message: mealPresenter.toastMessage,
                        isSuccess: mealPresenter.toastIsSuccess,
                        onDismiss: {
                            withAnimation {
                                mealPresenter.showToast = false
                            }
                        }
                    )
                    .padding(.top, 50) // Add padding to position below navigation bar
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: mealPresenter.showToast)
                .zIndex(100) // Ensure toast appears above all other content
            }
        }
        .onAppear {
            // Test toast on appear (for debugging)
            // Uncomment to test toast visibility
            /*
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                mealPresenter.toastMessage = "Test toast message"
                mealPresenter.toastIsSuccess = true
                mealPresenter.showToast = true
            }
            */
        }
    }
    
    private var todayMeals: [MealHistoryResponse.MealHistoryItem] {
        print("Total meal history items: \(mealPresenter.mealHistory.count)")
        
        // Extract today's month and day
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        print("Today's month-day: \(month)-\(day)")
        
        let filteredMeals = mealPresenter.mealHistory.filter { meal in
            print("Checking meal: \(meal.id), date: \(meal.createdAt)")
            
            // Extract month and day from the meal date string
            // Format is like: 2025-03-06T09:06:38.998700
            let components = meal.createdAt.split(separator: "-")
            if components.count >= 3 {
                let monthStr = components[1]
                let dayStr = components[2].prefix(2)
                
                if let mealMonth = Int(monthStr), let mealDay = Int(dayStr) {
                    let isSameMonthDay = (mealMonth == month && mealDay == day)
                    print("Meal month-day: \(mealMonth)-\(mealDay), matches today: \(isSameMonthDay)")
                    return isSameMonthDay
                }
            }
            
            print("Failed to extract month-day from date: \(meal.createdAt)")
            return false
        }
        
        print("Filtered today's meals: \(filteredMeals.count)")
        return filteredMeals
    }
    
    private func formatTime(from dateString: String) -> String {
        // Extract just the time portion
        if let timeComponent = dateString.split(separator: "T").last?.split(separator: ".").first {
            let timeString = String(timeComponent)
            
            // Convert from 24-hour to 12-hour format
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            
            if let date = timeFormatter.date(from: timeString) {
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "h:mm a"
                return outputFormatter.string(from: date)
            }
        }
        
        // Fallback to just showing the raw time component
        if let timeComponent = dateString.split(separator: "T").last {
            return String(timeComponent.prefix(5))
        }
        
        return ""
    }
}

struct DailyNutritionView_Previews: PreviewProvider {
    static var previews: some View {
        DailyNutritionView()
            .environmentObject(UserPresenter())
            .environmentObject(MealPresenter())
    }
} 