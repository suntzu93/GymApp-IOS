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
        APIService.shared.deleteMeal(mealId: mealId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    if let userId = self?.meals.first?.userId {
                        self?.loadData(userId: userId)
                    }
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