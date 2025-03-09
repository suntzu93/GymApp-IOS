import Foundation
import Combine

class MealPresenter: ObservableObject {
    @Published var selectedFoods: [Food] = []
    @Published var quantities: [String: Double] = [:]
    @Published var mealHistory: [MealHistoryResponse.MealHistoryItem] = []
    @Published var dailyNutrition: DailyNutrition = DailyNutrition()
    @Published var isLoading = false
    @Published var error: String?
    @Published var mealAddedFromSuggestions = false
    
    // Toast message state
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastIsSuccess = true
    
    @Published var selectedMealDetail: MealDetailResponse?
    @Published var isFetchingMealDetail = false
    @Published var mealDetailError: String?
    
    // Meal Plan properties
    @Published var mealPlan: MealPlanResponse?
    @Published var isFetchingMealPlan = false
    @Published var mealPlanError: String?
    @Published var lastMealPlanFetchDate: Date?
    
    private let apiService = APIService.shared
    public var cancellables = Set<AnyCancellable>()
    
    // Cache keys
    private let mealPlanCacheKey = "cached_meal_plan"
    private let mealPlanDateCacheKey = "cached_meal_plan_date"
    
    init() {
        // Load cached meal plan data on initialization
        loadCachedMealPlan()
    }
    
    struct DailyNutrition {
        var consumedCalories: Int = 0
        var consumedProtein: Double = 0
        var consumedFat: Double = 0
        var consumedCarbs: Double = 0
    }
    
    // MARK: - Caching Methods
    
    private func loadCachedMealPlan() {
        if let cachedData = UserDefaults.standard.data(forKey: mealPlanCacheKey) {
            do {
                let decoder = JSONDecoder()
                let cachedMealPlan = try decoder.decode(MealPlanResponse.self, from: cachedData)
                self.mealPlan = cachedMealPlan
                
                if let dateData = UserDefaults.standard.object(forKey: mealPlanDateCacheKey) as? Date {
                    self.lastMealPlanFetchDate = dateData
                }
                
                print("Loaded cached meal plan data")
            } catch {
                print("Error decoding cached meal plan: \(error)")
            }
        }
    }
    
    private func cacheMealPlan(_ mealPlan: MealPlanResponse) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(mealPlan)
            UserDefaults.standard.set(data, forKey: mealPlanCacheKey)
            
            let currentDate = Date()
            UserDefaults.standard.set(currentDate, forKey: mealPlanDateCacheKey)
            self.lastMealPlanFetchDate = currentDate
            
            print("Cached meal plan data")
        } catch {
            print("Error caching meal plan: \(error)")
        }
    }
    
    // MARK: - Meal Methods
    
    func addFoodToMeal(_ food: Food, quantity: Double = 100) {
        if !selectedFoods.contains(where: { $0.id == food.id }) {
            selectedFoods.append(food)
        }
        quantities[food.id] = quantity
    }
    
    func removeFoodFromMeal(_ food: Food) {
        selectedFoods.removeAll { $0.id == food.id }
        quantities.removeValue(forKey: food.id)
    }
    
    func updateQuantity(for food: Food, quantity: Double) {
        // Only update the quantity if this food doesn't have the _no_scale flag
        if quantities[food.id + "_no_scale"] == nil {
            quantities[food.id] = quantity
        }
    }
    
    func calculateMealNutrition() -> (calories: Int, protein: Double, fat: Double, carbs: Double) {
        var totalCalories = 0
        var totalProtein: Double = 0
        var totalFat: Double = 0
        var totalCarbs: Double = 0
        
        for food in selectedFoods {
            let quantity = quantities[food.id] ?? 100
            
            // Check if this food should not be scaled (comes from meal plan)
            if quantities[food.id + "_no_scale"] != nil {
                // Use the values directly without scaling
                totalCalories += food.calories
                totalProtein += food.protein
                totalFat += food.fat
                totalCarbs += food.carbs
            } else {
                // Scale based on quantity for manually added foods
                let ratio = quantity / 100.0
                
                totalCalories += Int(Double(food.calories) * ratio)
                totalProtein += food.protein * ratio
                totalFat += food.fat * ratio
                totalCarbs += food.carbs * ratio
            }
        }
        
        return (totalCalories, totalProtein, totalFat, totalCarbs)
    }
    
    func submitMeal(userId: String, mealType: MealType, fromSuggestions: Bool = false) {
        guard !selectedFoods.isEmpty else {
            error = "No foods selected"
            return
        }
        
        isLoading = true
        error = nil
        mealAddedFromSuggestions = fromSuggestions
        
        // Convert string IDs to integers
        let userIdInt = Int(userId) ?? 0
        
        // Calculate meal nutrition
        let nutrition = calculateMealNutrition()
        
        // Create meal items
        let mealItems = selectedFoods.map { food in
            let foodIdInt = Int(food.id) ?? 0
            let quantity = quantities[food.id] ?? 100
            
            // Check if this food should not be scaled (comes from meal plan)
            if quantities[food.id + "_no_scale"] != nil {
                // Use the values directly without scaling
                return MealRequest.MealItem(
                    foodId: foodIdInt,
                    quantity: quantity,
                    portionSize: 100.0,
                    calories: food.calories,
                    protein: food.protein,
                    fat: food.fat,
                    carbs: food.carbs,
                    foodName: food.name
                )
            } else {
                // Scale based on quantity for manually added foods
                let ratio = quantity / 100.0
                
                return MealRequest.MealItem(
                    foodId: foodIdInt,
                    quantity: quantity,
                    portionSize: 100.0,
                    calories: Int(Double(food.calories) * ratio),
                    protein: food.protein * ratio,
                    fat: food.fat * ratio,
                    carbs: food.carbs * ratio,
                    foodName: food.name
                )
            }
        }
        
        let mealRequest = MealRequest(
            userId: userIdInt,
            mealName: mealType.rawValue,
            totalCalories: nutrition.calories,
            totalProtein: nutrition.protein,
            totalFat: nutrition.fat,
            totalCarbs: nutrition.carbs,
            items: mealItems
        )
        
        apiService.addMeal(request: mealRequest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error.message
                    print("Add meal error: \(error.message)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // The meal was successfully added
                print("Meal added successfully with ID: \(response.id)")
                
                // Update daily nutrition
                self.dailyNutrition.consumedCalories += nutrition.calories
                self.dailyNutrition.consumedProtein += nutrition.protein
                self.dailyNutrition.consumedFat += nutrition.fat
                self.dailyNutrition.consumedCarbs += nutrition.carbs
                
                // Clear selected foods
                self.selectedFoods = []
                self.quantities = [:]
                
                // Fetch updated meal history
                self.fetchMealHistory(userId: userId)
                
                // Publish a notification that meal was added successfully
                NotificationCenter.default.post(
                    name: NSNotification.Name("MealAddedSuccessfully"),
                    object: nil,
                    userInfo: ["fromSuggestions": fromSuggestions]
                )
            }
            .store(in: &cancellables)
    }
    
    func fetchMealHistory(userId: String) {
        isLoading = true
        error = nil
        
        apiService.getMealHistory(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error.message
                    print("Error fetching meal history: \(error.message)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if response.success {
                    print("Successfully received meal history with \(response.data.count) items")
                    self.mealHistory = response.data
                    self.calculateDailyNutrition(from: response.data)
                } else {
                    self.error = "Failed to fetch meal history"
                    print("Failed to fetch meal history: success=false")
                }
            }
            .store(in: &cancellables)
    }
    
    private func calculateDailyNutrition(from meals: [MealHistoryResponse.MealHistoryItem]) {
        // Reset daily nutrition
        dailyNutrition = DailyNutrition()
        
        // Extract today's month and day
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        print("Calculating daily nutrition from \(meals.count) meals")
        print("Today's month-day for nutrition: \(month)-\(day)")
        
        let todayMeals = meals.filter { meal in
            print("Checking meal for nutrition: \(meal.id), date: \(meal.createdAt)")
            
            // Extract month and day from the meal date string
            // Format is like: 2025-03-06T09:06:38.998700
            let components = meal.createdAt.split(separator: "-")
            if components.count >= 3 {
                let monthStr = components[1]
                let dayStr = components[2].prefix(2)
                
                if let mealMonth = Int(monthStr), let mealDay = Int(dayStr) {
                    let isSameMonthDay = (mealMonth == month && mealDay == day)
                    print("Meal month-day for nutrition: \(mealMonth)-\(mealDay), matches today: \(isSameMonthDay)")
                    return isSameMonthDay
                }
            }
            
            print("Failed to extract month-day from date for nutrition: \(meal.createdAt)")
            return false
        }
        
        print("Today's meals for nutrition calculation: \(todayMeals.count)")
        
        // Sum up nutrition values
        for meal in todayMeals {
            print("Adding nutrition from meal \(meal.id): calories=\(meal.totalCalories), protein=\(meal.totalProtein), fat=\(meal.totalFat), carbs=\(meal.totalCarbs)")
            dailyNutrition.consumedCalories += meal.totalCalories
            dailyNutrition.consumedProtein += meal.totalProtein
            dailyNutrition.consumedFat += meal.totalFat
            dailyNutrition.consumedCarbs += meal.totalCarbs
        }
        
        print("Final daily nutrition: calories=\(dailyNutrition.consumedCalories), protein=\(dailyNutrition.consumedProtein), fat=\(dailyNutrition.consumedFat), carbs=\(dailyNutrition.consumedCarbs)")
    }
    
    func clearMeal() {
        selectedFoods = []
        quantities = [:]
    }
    
    func refreshDailyNutrition() {
        if !mealHistory.isEmpty {
            calculateDailyNutrition(from: mealHistory)
        }
    }
    
    func deleteMeal(mealId: String, userId: String) {
        print("MealPresenter: Attempting to delete meal with ID: \(mealId)")
        isLoading = true
        error = nil
        
        apiService.deleteMeal(mealId: mealId, userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error.message
                    print("Error deleting meal: \(error.message)")
                    
                    // Show error toast
                    self?.toastMessage = "Failed to delete meal: \(error.message)"
                    self?.toastIsSuccess = false
                    print("Setting error toast: \(error.message)")
                    self?.showToast = true
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                print("Meal deleted successfully: \(response)")
                
                // Remove the meal from the history
                let beforeCount = self.mealHistory.count
                self.mealHistory.removeAll { $0.mealId == mealId }
                let afterCount = self.mealHistory.count
                print("Removed meal from history: before=\(beforeCount), after=\(afterCount)")
                
                // Recalculate daily nutrition
                self.calculateDailyNutrition(from: self.mealHistory)
                
                // Show success toast
                self.toastMessage = "Meal deleted successfully"
                self.toastIsSuccess = true
                print("Setting success toast: Meal deleted successfully")
                
                // Important: Set showToast to true AFTER setting the message and success state
                DispatchQueue.main.async {
                    self.showToast = true
                    print("Toast visibility set to: \(self.showToast)")
                }
                
                // Fetch updated meal history to ensure everything is in sync
                self.fetchMealHistory(userId: userId)
            }
            .store(in: &cancellables)
    }
    
    func getMealDetails(mealId: String, userId: String) {
        isFetchingMealDetail = true
        mealDetailError = nil
        
        apiService.getMealDetails(mealId: mealId, userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isFetchingMealDetail = false
                
                if case .failure(let error) = completion {
                    self?.mealDetailError = error.message
                    print("Error fetching meal details: \(error.message)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                print("Successfully received meal details for meal ID: \(response.id)")
                self.selectedMealDetail = response
            }
            .store(in: &cancellables)
    }
    
    func fetchDailyMealPlan(userId: String, forceRefresh: Bool = false) {
        // If we're not forcing a refresh and we already have data, don't fetch again
        if !forceRefresh && mealPlan != nil {
            print("Using existing meal plan data")
            return
        }
        
        isFetchingMealPlan = true
        mealPlanError = nil
        
        apiService.getDailyMealPlan(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isFetchingMealPlan = false
                
                if case .failure(let error) = completion {
                    self?.mealPlanError = error.message
                    print("Error fetching meal plan: \(error.message)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                print("Successfully received meal plan")
                self.mealPlan = response
                
                // Cache the meal plan data
                self.cacheMealPlan(response)
            }
            .store(in: &cancellables)
    }
    
    func addFoodFromMealPlan(_ food: MealPlanResponse.MealFood) {
        // Extract quantity from string (e.g., "100g" -> 100.0)
        let quantityString = food.quantity.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let quantity = Double(quantityString) ?? 100.0
        
        // Convert MealFood to Food - use the values directly without assuming they're per 100g
        let newFood = Food(
            id: UUID().uuidString, // Generate a temporary ID
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            fat: food.fat,
            carbs: food.carbs,
            country: "",
            city: ""
        )
        
        // Add to selected foods with the exact quantity from the meal plan
        // This ensures we don't scale the nutritional values
        addFoodToMeal(newFood, quantity: quantity)
        
        // Override the default scaling behavior in the quantities dictionary
        // by setting a special flag to indicate this food's values should not be scaled
        quantities[newFood.id + "_no_scale"] = 1.0
    }
} 