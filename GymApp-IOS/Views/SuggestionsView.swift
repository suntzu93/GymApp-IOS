import SwiftUI
import UIKit

struct SuggestionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userPresenter: UserPresenter
    @EnvironmentObject var mealPresenter: MealPresenter
    @EnvironmentObject var foodPresenter: FoodPresenter
    
    @State private var showingAddMealSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if let user = userPresenter.user {
                        // Calculate remaining nutrition values separately
                        let remainingCalories = (user.dailyCalories ?? 0) - mealPresenter.dailyNutrition.consumedCalories
                        let remainingProtein = (user.dailyProtein ?? 0) - mealPresenter.dailyNutrition.consumedProtein
                        let remainingFat = (user.dailyFat ?? 0) - mealPresenter.dailyNutrition.consumedFat
                        let remainingCarbs = (user.dailyCarbs ?? 0) - mealPresenter.dailyNutrition.consumedCarbs
                        
                        // Display remaining nutrition card
                        NutritionCard(
                            title: "remaining".localized,
                            calories: remainingCalories,
                            protein: remainingProtein,
                            fat: remainingFat,
                            carbs: remainingCarbs,
                            backgroundColor: Color(uiColor: .secondarySystemBackground)
                        )
                        .padding()
                        
                        Text("suggestions_subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    // Loading state
                    if foodPresenter.isLoading {
                        Spacer()
                        LoadingView()
                        Spacer()
                    } 
                    // Error state
                    else if let error = foodPresenter.error {
                        Spacer()
                        ErrorView(message: error) {
                            if let userId = userPresenter.user?.id {
                                foodPresenter.getSuggestions(userId: userId)
                            }
                        }
                        Spacer()
                    } 
                    // Empty state
                    else if foodPresenter.suggestions.isEmpty {
                        Spacer()
                        EmptyStateView(
                            title: "no_suggestions".localized,
                            message: "We couldn't find any suggestions based on your remaining nutrition goals",
                            systemImage: "lightbulb.slash"
                        )
                        Spacer()
                    } 
                    // Suggestions list
                    else {
                        suggestionsList
                    }
                }
                .navigationTitle("suggestions_title".localized)
                .navigationBarItems(
                    trailing: Button("done".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .onAppear {
                    if let userId = userPresenter.user?.id {
                        foodPresenter.getSuggestions(userId: userId)
                    }
                }
                .sheet(isPresented: $showingAddMealSheet) {
                    AddMealView(fromSuggestions: true)
                }
            }
        }
    }
    
    // Extract suggestions list to a separate computed property
    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(foodPresenter.suggestions, id: \.identifier) { suggestion in
                    suggestionCard(for: suggestion)
                }
            }
            .padding()
        }
    }
    
    // Extract suggestion card to a separate method
    private func suggestionCard(for suggestion: AISuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(suggestion.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            nutrientBadgesRow(for: suggestion)
            
            addToMealButton(for: suggestion)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // Extract nutrient badges to a separate method
    private func nutrientBadgesRow(for suggestion: AISuggestion) -> some View {
        HStack(spacing: 16) {
            NutrientBadge(
                value: "\(suggestion.calories)",
                unit: "kcal".localized,
                color: .red
            )
            
            NutrientBadge(
                value: String(format: "%.1f", suggestion.protein),
                unit: "g".localized + " " + "protein".localized,
                color: .blue
            )
            
            NutrientBadge(
                value: String(format: "%.1f", suggestion.fat),
                unit: "g".localized + " " + "fat".localized,
                color: .yellow
            )
            
            NutrientBadge(
                value: String(format: "%.1f", suggestion.carbs),
                unit: "g".localized + " " + "carbs".localized,
                color: .green
            )
        }
    }
    
    // Extract add to meal button to a separate method
    private func addToMealButton(for suggestion: AISuggestion) -> some View {
        Button(action: {
            // Convert AISuggestion to Food
            let food = Food(
                id: String(suggestion.id),
                name: suggestion.suggestedFood,
                description: nil,
                calories: suggestion.calories,
                protein: suggestion.protein,
                fat: suggestion.fat,
                carbs: suggestion.carbs,
                country: userPresenter.user?.country ?? "",
                city: userPresenter.user?.city ?? ""
            )
            
            mealPresenter.addFoodToMeal(food)
            showingAddMealSheet = true
        }) {
            Label("add_to_meal".localized, systemImage: "plus.circle")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

struct SuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionsView()
            .environmentObject(UserPresenter())
            .environmentObject(FoodPresenter())
            .environmentObject(MealPresenter())
    }
} 