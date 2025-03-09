import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

struct Meal: Codable, Identifiable {
    var id: String
    var userId: String
    var mealName: MealType
    var totalCalories: Int
    var totalProtein: Double
    var totalFat: Double
    var totalCarbs: Double
    var createdAt: Date?
}

struct MealItem: Codable, Identifiable {
    var id: String
    var mealId: String
    var foodId: String
    var quantity: Double
    var calories: Int
    var protein: Double
    var fat: Double
    var carbs: Double
}

struct MealRequest: Codable {
    var userId: Int
    var mealName: String
    var totalCalories: Int
    var totalProtein: Double
    var totalFat: Double
    var totalCarbs: Double
    var items: [MealItem]
    
    struct MealItem: Codable {
        var foodId: Int
        var quantity: Double
        var portionSize: Double
        var calories: Int
        var protein: Double
        var fat: Double
        var carbs: Double
        
        enum CodingKeys: String, CodingKey {
            case foodId = "food_id"
            case quantity
            case portionSize = "portion_size"
            case calories
            case protein
            case fat
            case carbs
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case mealName = "meal_name"
        case totalCalories = "total_calories"
        case totalProtein = "total_protein"
        case totalFat = "total_fat"
        case totalCarbs = "total_carbs"
        case items
    }
}

struct MealResponse: Codable {
    var id: Int
    var userId: Int
    var mealName: String
    var totalCalories: Int
    var totalProtein: Double
    var totalFat: Double
    var totalCarbs: Double
    var createdAt: String
    var items: [MealItemResponse]
    
    struct MealItemResponse: Codable {
        var id: Int
        var mealId: Int
        var foodId: Int
        var quantity: Double
        var portionSize: Double
        var calories: Int
        var protein: Double
        var fat: Double
        var carbs: Double
        var foodName: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case mealId = "meal_id"
            case foodId = "food_id"
            case quantity
            case portionSize = "portion_size"
            case calories
            case protein
            case fat
            case carbs
            case foodName = "food_name"
        }
    }
    
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
    
    // Add a computed property to indicate success
    var success: Bool { true }
}

struct MealHistoryResponse: Codable {
    var success: Bool
    var data: [MealHistoryItem]
    
    init(success: Bool, data: [MealHistoryItem]) {
        self.success = success
        self.data = data
        print("Created MealHistoryResponse with \(data.count) items")
        for item in data {
            print("Meal item: id=\(item.id), name=\(item.mealName), date=\(item.createdAt)")
        }
    }
    
    struct MealHistoryItem: Codable, Identifiable {
        var id: String { mealId }
        var mealId: String
        var mealName: String
        var totalCalories: Int
        var totalProtein: Double
        var totalFat: Double
        var totalCarbs: Double
        var createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case mealId = "meal_id"
            case mealName = "meal_name"
            case totalCalories = "total_calories"
            case totalProtein = "total_protein"
            case totalFat = "total_fat"
            case totalCarbs = "total_carbs"
            case createdAt = "created_at"
        }
        
        // Custom initializer to handle potential type mismatches
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // First try to decode the id directly
            if container.contains(.id) {
                if let idInt = try? container.decode(Int.self, forKey: .id) {
                    mealId = String(idInt)
                } else if let idString = try? container.decode(String.self, forKey: .id) {
                    mealId = idString
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "ID must be a string or integer")
                }
            } 
            // If id is not present, try meal_id
            else if container.contains(.mealId) {
                if let idString = try? container.decode(String.self, forKey: .mealId) {
                    mealId = idString
                } else if let idInt = try? container.decode(Int.self, forKey: .mealId) {
                    mealId = String(idInt)
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .mealId, in: container, debugDescription: "Meal ID must be a string or integer")
                }
            } else {
                throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Neither id nor meal_id found", underlyingError: nil))
            }
            
            mealName = try container.decode(String.self, forKey: .mealName)
            
            // Handle numeric values that could be integers or doubles
            if let caloriesInt = try? container.decode(Int.self, forKey: .totalCalories) {
                totalCalories = caloriesInt
            } else if let caloriesDouble = try? container.decode(Double.self, forKey: .totalCalories) {
                totalCalories = Int(caloriesDouble)
            } else {
                totalCalories = 0
                print("Warning: Could not decode totalCalories as Int or Double")
            }
            
            if let proteinDouble = try? container.decode(Double.self, forKey: .totalProtein) {
                totalProtein = proteinDouble
            } else if let proteinInt = try? container.decode(Int.self, forKey: .totalProtein) {
                totalProtein = Double(proteinInt)
            } else {
                totalProtein = 0.0
                print("Warning: Could not decode totalProtein as Double or Int")
            }
            
            if let fatDouble = try? container.decode(Double.self, forKey: .totalFat) {
                totalFat = fatDouble
            } else if let fatInt = try? container.decode(Int.self, forKey: .totalFat) {
                totalFat = Double(fatInt)
            } else {
                totalFat = 0.0
                print("Warning: Could not decode totalFat as Double or Int")
            }
            
            if let carbsDouble = try? container.decode(Double.self, forKey: .totalCarbs) {
                totalCarbs = carbsDouble
            } else if let carbsInt = try? container.decode(Int.self, forKey: .totalCarbs) {
                totalCarbs = Double(carbsInt)
            } else {
                totalCarbs = 0.0
                print("Warning: Could not decode totalCarbs as Double or Int")
            }
            
            createdAt = try container.decode(String.self, forKey: .createdAt)
        }
        
        // Add encode method to make the struct conform to Encodable
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            // Encode using meal_id since that's what the server expects
            try container.encode(mealId, forKey: .mealId)
            try container.encode(mealName, forKey: .mealName)
            try container.encode(totalCalories, forKey: .totalCalories)
            try container.encode(totalProtein, forKey: .totalProtein)
            try container.encode(totalFat, forKey: .totalFat)
            try container.encode(totalCarbs, forKey: .totalCarbs)
            try container.encode(createdAt, forKey: .createdAt)
        }
    }
    
    struct MealItemResponse: Codable {
        var id: Int
        var mealId: Int
        var foodId: Int
        var quantity: Double
        var portionSize: Double
        var calories: Int
        var protein: Double
        var fat: Double
        var carbs: Double
        var foodName: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case mealId = "meal_id"
            case foodId = "food_id"
            case quantity
            case portionSize = "portion_size"
            case calories
            case protein
            case fat
            case carbs
            case foodName = "food_name"
        }
    }
}

// Model for meal detail response
struct MealDetailResponse: Codable, Identifiable {
    var id: Int
    var userId: Int
    var mealName: String
    var totalCalories: Int
    var totalProtein: Double
    var totalFat: Double
    var totalCarbs: Double
    var createdAt: String
    var items: [MealItemDetail]
    
    struct MealItemDetail: Codable, Identifiable {
        var id: Int
        var mealId: Int
        var foodId: Int
        var quantity: Double
        var portionSize: Double
        var calories: Int
        var protein: Double
        var fat: Double
        var carbs: Double
        var foodName: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case mealId = "meal_id"
            case foodId = "food_id"
            case quantity
            case portionSize = "portion_size"
            case calories
            case protein
            case fat
            case carbs
            case foodName = "food_name"
        }
    }
    
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

// Model for daily meal plan
struct MealPlanResponse: Codable {
    var userInfo: UserInfo
    var dietaryRestrictions: [String]
    var mealPlan: MealPlan
    var totalNutrition: NutritionTotals
    
    struct UserInfo: Codable {
        var gender: String
        var age: Int
        var weight: Double
        var height: Double
        var bmi: Double
        var goal: String
        var country: String
        var city: String
    }
    
    struct MealPlan: Codable {
        var dailyTotals: NutritionTotals
        var breakfast: MealSection
        var lunch: MealSection
        var dinner: MealSection
        var snacks: MealSection
    }
    
    struct MealSection: Codable {
        var foods: [MealFood]
        var totals: NutritionTotals
    }
    
    struct MealFood: Codable, Identifiable {
        var id: String { name }
        var name: String
        var quantity: String
        var calories: Int
        var protein: Double
        var fat: Double
        var carbs: Double
    }
    
    struct NutritionTotals: Codable {
        var calories: Int
        var protein: Double
        var fat: Double
        var carbs: Double
    }
} 