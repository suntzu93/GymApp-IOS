import SwiftUI
import UIKit

struct FoodListView: View {
    @EnvironmentObject var userPresenter: UserPresenter
    @EnvironmentObject var foodPresenter: FoodPresenter
    @EnvironmentObject var mealPresenter: MealPresenter
    @Environment(\.presentationMode) var presentationMode
    
    // Parameter to determine if we're selecting foods for a meal
    var isSelecting: Bool = false
    
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showingAddMealSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Search Bar
                    HStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            TextField("search_food".localized, text: $searchText)
                                .padding(.vertical, 10)
                                .onChange(of: searchText) { newValue in
                                    if newValue.isEmpty && isSearching {
                                        // Reset to show all foods when search text is cleared
                                        isSearching = false
                                        if let user = userPresenter.user {
                                            foodPresenter.fetchFoodList(country: user.country, city: user.city)
                                        }
                                    }
                                }
                        }
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(10)
                        
                        Button(action: {
                            if !searchText.isEmpty {
                                isSearching = true
                                foodPresenter.searchFood(query: searchText)
                            }
                        }) {
                            Text("Search")
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(searchText.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(searchText.isEmpty)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                isSearching = false
                                // Reset to show all foods when search is cleared
                                if let user = userPresenter.user {
                                    foodPresenter.fetchFoodList(country: user.country, city: user.city)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .padding(10)
                            }
                        }
                    }
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
                                                showActions: true,
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
                                                    if isSelecting {
                                                        presentationMode.wrappedValue.dismiss()
                                                    } else {
                                                        showingAddMealSheet = true
                                                    }
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
                                                showActions: true,
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
                                                    if isSelecting {
                                                        presentationMode.wrappedValue.dismiss()
                                                    } else {
                                                        showingAddMealSheet = true
                                                    }
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
                .navigationTitle(isSelecting ? "Select Food" : "food_list_title".localized)
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