import SwiftUI
import UIKit

struct FoodListView: View {
    @EnvironmentObject var userPresenter: UserPresenter
    @EnvironmentObject var foodPresenter: FoodPresenter
    @EnvironmentObject var mealPresenter: MealPresenter
    
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showingAddMealSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("search_food".localized, text: $searchText)
                            .onChange(of: searchText) { newValue in
                                if newValue.isEmpty {
                                    isSearching = false
                                } else {
                                    isSearching = true
                                    foodPresenter.searchFood(query: newValue)
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                isSearching = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    if foodPresenter.isLoading {
                        Spacer()
                        LoadingView()
                        Spacer()
                    } else if let error = foodPresenter.error {
                        Spacer()
                        ErrorView(message: error) {
                            if isSearching {
                                foodPresenter.searchFood(query: searchText)
                            } else if let user = userPresenter.user {
                                foodPresenter.fetchFoodList(country: user.country, city: user.city)
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if isSearching {
                                    if foodPresenter.searchResults.isEmpty {
                                        EmptyStateView(
                                            title: "no_foods_found".localized,
                                            message: "Try searching for something else",
                                            systemImage: "magnifyingglass"
                                        )
                                    } else {
                                        ForEach(foodPresenter.searchResults) { food in
                                            FoodItemRow(
                                                food: food,
                                                onAddToFavorites: {
                                                    if let userId = userPresenter.user?.id {
                                                        foodPresenter.saveFoodPreference(
                                                            userId: userId,
                                                            foodId: food.id
                                                        )
                                                    }
                                                },
                                                onAddToMeal: {
                                                    mealPresenter.addFoodToMeal(food)
                                                    showingAddMealSheet = true
                                                }
                                            )
                                        }
                                    }
                                } else {
                                    if foodPresenter.foods.isEmpty {
                                        EmptyStateView(
                                            title: "no_foods_found".localized,
                                            message: "Popular foods in your area will appear here",
                                            systemImage: "fork.knife"
                                        )
                                    } else {
                                        ForEach(foodPresenter.foods) { food in
                                            FoodItemRow(
                                                food: food,
                                                onAddToFavorites: {
                                                    if let userId = userPresenter.user?.id {
                                                        foodPresenter.saveFoodPreference(
                                                            userId: userId,
                                                            foodId: food.id
                                                        )
                                                    }
                                                },
                                                onAddToMeal: {
                                                    mealPresenter.addFoodToMeal(food)
                                                    showingAddMealSheet = true
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("food_list_title".localized)
                .onAppear {
                    if let user = userPresenter.user {
                        foodPresenter.fetchFoodList(country: user.country, city: user.city)
                    }
                }
                .sheet(isPresented: $showingAddMealSheet) {
                    AddMealView()
                }
            }
        }
    }
}

struct FoodListView_Previews: PreviewProvider {
    static var previews: some View {
        FoodListView()
            .environmentObject(UserPresenter())
            .environmentObject(FoodPresenter())
            .environmentObject(MealPresenter())
    }
} 