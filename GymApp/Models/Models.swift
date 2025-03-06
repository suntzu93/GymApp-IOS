import Foundation

// User model
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let gender: String
    let age: Int
    let weight: Double
    let height: Double
    let activityLevel: String
    let goal: String
    let country: String
    let city: String
    let language: String
    let dailyCalories: Int?
    let dailyProtein: Double?
    let dailyFat: Double?
    let dailyCarbs: Double?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, gender, age, weight, height, country, city, language, created_at
        case activityLevel = "activity_level"
        case goal
        case dailyCalories = "daily_calories"
        case dailyProtein = "daily_protein"
        case dailyFat = "daily_fat"
        case dailyCarbs = "daily_carbs"
        case createdAt = "created_at"
    }
}

// User registration model
struct UserRegistration: Codable {
    let name: String
    let gender: String
    let age: Int
    let weight: Double
    let height: Double
    let activityLevel: String
    let goal: String
    let country: String
    let city: String
    let language: String
    
    enum CodingKeys: String, CodingKey {
        case name, gender, age, weight, height, country, city, language
        case activityLevel = "activity_level"
        case goal
    }
}

// Food item model
struct FoodItem: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let portionSize: Double
    let country: String
    let city: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, calories, protein, fat, carbs, country, city
        case portionSize = "portion_size"
        case createdAt = "created_at"
    }
}

// Meal model
struct Meal: Codable, Identifiable {
    let id: Int
    let userId: Int
    let mealName: String
    let totalCalories: Int
    let totalProtein: Double
    let totalFat: Double
    let totalCarbs: Double
    let createdAt: String
    let items: [MealItem]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mealName = "meal_name"
        case totalCalories = "total_calories"
        case totalProtein = "total_protein"
        case totalFat = "total_fat"
        case totalCarbs = "total_carbs"
        case createdAt = "created_at"
        case items
    }
}

// Meal item model
struct MealItem: Codable, Identifiable {
    let id: Int
    let mealId: Int
    let foodId: Int
    let quantity: Double
    let portionSize: Double
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealId = "meal_id"
        case foodId = "food_id"
        case quantity, calories, protein, fat, carbs
        case portionSize = "portion_size"
    }
}

// Food suggestion model
struct FoodSuggestion: Codable, Identifiable {
    let id: Int
    let userId: Int
    let suggestedFood: String
    let calories: Int?
    let protein: Double?
    let fat: Double?
    let carbs: Double?
    let portionSize: Double
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case suggestedFood = "suggested_food"
        case calories, protein, fat, carbs
        case portionSize = "portion_size"
        case createdAt = "created_at"
    }
}

// Nutrition summary model
struct NutritionSummary: Codable {
    let consumed: Nutrition
    let goals: Nutrition
    let remaining: Nutrition
}

// Nutrition model
struct Nutrition: Codable {
    let calories: Int?
    let protein: Double?
    let fat: Double?
    let carbs: Double?
}

// Food preference model
struct FoodPreference: Codable, Identifiable {
    let id: Int
    let userId: Int
    let foodId: Int
    let preference: String
    let createdAt: String
    let food: FoodItem
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case foodId = "food_id"
        case preference
        case createdAt = "created_at"
        case food
    }
}

// Add meal request model
struct AddMealRequest: Codable {
    let userId: Int
    let mealName: String
    let foodItems: [AddMealFoodItem]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case mealName = "meal_name"
        case foodItems = "food_items"
    }
}

// Add meal food item model
struct AddMealFoodItem: Codable {
    let foodId: Int
    let quantity: Double
    
    enum CodingKeys: String, CodingKey {
        case foodId = "food_id"
        case quantity
    }
} 