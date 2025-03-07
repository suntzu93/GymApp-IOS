import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var suggestions: [FoodSuggestion] = []
    @Published var nutritionSummary: NutritionSummary?
    @Published var isLoadingMeals: Bool = false
    @Published var isLoadingSuggestions: Bool = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadData(userId: Int) {
        loadMeals(userId: userId)
        loadNutritionSummary(userId: userId)
        loadSuggestions(userId: userId)
    }
    
    func loadMeals(userId: Int) {
        isLoadingMeals = true
        error = nil
        
        let today = formatDate(Date())
        
        APIService.shared.getUserMeals(userId: userId, date: today)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingMeals = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] meals in
                    self?.meals = meals
                }
            )
            .store(in: &cancellables)
    }
    
    func loadNutritionSummary(userId: Int) {
        APIService.shared.getTodayNutrition(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] summary in
                    self?.nutritionSummary = summary
                }
            )
            .store(in: &cancellables)
    }
    
    func loadSuggestions(userId: Int) {
        APIService.shared.getSuggestionHistory(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] suggestions in
                    self?.suggestions = suggestions
                }
            )
            .store(in: &cancellables)
    }
    
    func getSuggestions(userId: Int) {
        isLoadingSuggestions = true
        error = nil
        
        APIService.shared.getSuggestions(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSuggestions = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] suggestions in
                    self?.suggestions = suggestions
                    self?.loadNutritionSummary(userId: userId)
                }
            )
            .store(in: &cancellables)
    }
    
    func addMeal(userId: Int, mealName: String, foodItems: [AddMealFoodItem]) {
        let meal = AddMealRequest(userId: userId, mealName: mealName, foodItems: foodItems)
        
        APIService.shared.addMeal(meal: meal)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] meal in
                    self?.loadData(userId: userId)
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteMeal(mealId: Int) {
        // Debug: Print the meals array to verify we have data
        print("DEBUG: Meals count: \(meals.count)")
        for meal in meals {
            print("DEBUG: Meal ID: \(meal.id), User ID: \(meal.userId)")
        }
        
        guard let userId = meals.first?.userId else {
            error = "Cannot delete meal: User ID not found"
            print("DEBUG: Error - User ID not found in meals array")
            return
        }
        
        print("DEBUG: Deleting meal with ID: \(mealId) for user ID: \(userId)")
        
        // Use the updated deleteMeal method
        APIService.shared.deleteMeal(mealId: mealId, userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                        print("DEBUG: Delete meal error: \(error.localizedDescription)")
                    } else {
                        print("DEBUG: Delete meal completion successful")
                    }
                },
                receiveValue: { [weak self] response in
                    print("DEBUG: Delete meal response: \(response)")
                    self?.loadData(userId: userId)
                }
            )
            .store(in: &cancellables)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
} 