import Foundation
import Combine

class FoodPresenter: ObservableObject {
    @Published var foods: [Food] = []
    @Published var searchResults: [Food] = []
    @Published var suggestions: [AISuggestion] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var likedFoodIds: Set<String> = []  // Track liked food IDs
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load liked food IDs from UserDefaults
        if let likedIds = UserDefaults.standard.array(forKey: "likedFoodIds") as? [String] {
            likedFoodIds = Set(likedIds)
        }
    }
    
    // Helper method to save liked food IDs to UserDefaults
    private func saveLikedFoodIds() {
        UserDefaults.standard.set(Array(likedFoodIds), forKey: "likedFoodIds")
    }
    
    // Helper method to sort foods with liked foods at the top
    private func sortFoodsWithLikedOnTop(_ foodList: [Food]) -> [Food] {
        return foodList.sorted { (food1, food2) -> Bool in
            if food1.isLiked && !food2.isLiked {
                return true
            } else if !food1.isLiked && food2.isLiked {
                return false
            } else {
                return food1.name < food2.name  // Secondary sort by name
            }
        }
    }
    
    func fetchFoodList(country: String, city: String) {
        isLoading = true
        error = nil
        
        apiService.getFoodList(country: country, city: city)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error.message
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if response.success {
                    // Mark liked foods
                    var updatedFoods = response.data
                    for i in 0..<updatedFoods.count {
                        if self.likedFoodIds.contains(updatedFoods[i].id) {
                            updatedFoods[i].isLiked = true
                        }
                    }
                    
                    // Sort with liked foods at the top
                    self.foods = self.sortFoodsWithLikedOnTop(updatedFoods)
                } else {
                    self.error = "Failed to fetch food list"
                }
            }
            .store(in: &cancellables)
    }
    
    func searchFood(query: String, country: String = "Vietnam", city: String = "Hanoi") {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        error = nil
        
        apiService.searchFood(query: query, country: country, city: city)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error.message
                    print("Search error: \(error.message)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if response.success {
                    // Mark liked foods
                    var updatedFoods = response.data
                    for i in 0..<updatedFoods.count {
                        if self.likedFoodIds.contains(updatedFoods[i].id) {
                            updatedFoods[i].isLiked = true
                        }
                    }
                    
                    // Sort with liked foods at the top
                    self.searchResults = self.sortFoodsWithLikedOnTop(updatedFoods)
                    print("Search found \(self.searchResults.count) results")
                } else {
                    self.error = "Failed to search foods"
                    print("Search failed: success=false")
                }
            }
            .store(in: &cancellables)
    }
    
    func saveFoodPreference(userId: String, foodId: String, preference: FoodPreference? = nil) {
        isLoading = true
        error = nil
        
        // Determine the preference based on current liked status
        let finalPreference: FoodPreference
        
        if preference == nil {
            // If no preference is specified, toggle the current status
            let isCurrentlyLiked = likedFoodIds.contains(foodId)
            finalPreference = isCurrentlyLiked ? .dislike : .like
        } else {
            finalPreference = preference!
        }
        
        apiService.saveFoodPreference(userId: userId, foodId: foodId, preference: finalPreference)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error.message
                    print("Error saving preference: \(error.message)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                print("Preference saved: \(response)")
                
                if finalPreference == .like {
                    // Add to liked foods
                    self.likedFoodIds.insert(foodId)
                    
                    // Update isLiked status in foods array
                    for i in 0..<self.foods.count {
                        if self.foods[i].id == foodId {
                            self.foods[i].isLiked = true
                        }
                    }
                    
                    // Update isLiked status in search results
                    for i in 0..<self.searchResults.count {
                        if self.searchResults[i].id == foodId {
                            self.searchResults[i].isLiked = true
                        }
                    }
                    
                    // Resort the lists
                    self.foods = self.sortFoodsWithLikedOnTop(self.foods)
                    self.searchResults = self.sortFoodsWithLikedOnTop(self.searchResults)
                    
                } else if finalPreference == .dislike {
                    // Remove from liked foods if present
                    self.likedFoodIds.remove(foodId)
                    
                    // Update isLiked status in foods array (don't remove, just mark as not liked)
                    for i in 0..<self.foods.count {
                        if self.foods[i].id == foodId {
                            self.foods[i].isLiked = false
                        }
                    }
                    
                    // Update isLiked status in search results
                    for i in 0..<self.searchResults.count {
                        if self.searchResults[i].id == foodId {
                            self.searchResults[i].isLiked = false
                        }
                    }
                    
                    // Resort the lists
                    self.foods = self.sortFoodsWithLikedOnTop(self.foods)
                    self.searchResults = self.sortFoodsWithLikedOnTop(self.searchResults)
                }
                
                // Save liked food IDs to UserDefaults
                self.saveLikedFoodIds()
            }
            .store(in: &cancellables)
    }
    
    func getSuggestions(userId: String) {
        isLoading = true
        error = nil
        
        apiService.getSuggestions(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error.message
                    print("Suggestion error: \(error.message)")
                }
            } receiveValue: { [weak self] response in
                // The response is now directly an array of suggestions
                self?.suggestions = response
                print("Received \(response.count) suggestions")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Custom Food Nutrition
    
    @Published var customFoodNutrition: FoodNutritionResponse?
    @Published var isLoadingCustomFood = false
    @Published var customFoodError: String?
    
    func getCustomFoodNutrition(foodName: String, userId: String, portion: Double = 100.0, mealPresenter: MealPresenter? = nil) {
        isLoadingCustomFood = true
        customFoodError = nil
        
        apiService.getFoodNutrition(foodName: foodName, userId: userId, portion: portion)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoadingCustomFood = false
                
                if case .failure(let error) = completion {
                    self?.customFoodError = error.message
                    print("Custom food nutrition error: \(error.message)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                print("Received custom food nutrition: \(response.foodName)")
                self.customFoodNutrition = response
                
                // Create a Food object from the nutrition response
                let customFood = self.createFoodFromNutrition(response)
                
                // Add the custom food to the meal if a meal presenter was provided
                if let mealPresenter = mealPresenter {
                    mealPresenter.addFoodToMeal(customFood, quantity: response.portion)
                }
            }
            .store(in: &cancellables)
    }
    
    private func createFoodFromNutrition(_ nutrition: FoodNutritionResponse) -> Food {
        // Generate a unique ID for the custom food
        let id = "custom_\(Date().timeIntervalSince1970)"
        
        // Create a Food object from the nutrition data
        return Food(
            id: id,
            name: nutrition.foodName,
            description: nutrition.standardServing,
            calories: nutrition.calories,
            protein: nutrition.protein,
            fat: nutrition.fat,
            carbs: nutrition.carbs,
            country: "Custom",
            city: nil,
            createdAt: Date(),
            isLiked: false
        )
    }
} 