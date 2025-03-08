import Foundation

struct Food: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var description: String?
    var calories: Int
    var protein: Double
    var fat: Double
    var carbs: Double
    var country: String
    var city: String?
    var createdAt: Date?
    var isLiked: Bool = false  // Add this property to track liked status
    
    // Add a standard initializer for use in previews and other places
    init(id: String, name: String, description: String? = nil, calories: Int, protein: Double, fat: Double, carbs: Double, country: String, city: String? = nil, createdAt: Date? = nil, isLiked: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.country = country
        self.city = city
        self.createdAt = createdAt
        self.isLiked = isLiked
    }
    
    // Add a custom initializer to handle potential type mismatches
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id which could be a string or an integer
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "ID must be a string or integer")
        }
        
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Handle numeric values that could be integers or doubles
        if let caloriesInt = try? container.decode(Int.self, forKey: .calories) {
            calories = caloriesInt
        } else if let caloriesDouble = try? container.decode(Double.self, forKey: .calories) {
            calories = Int(caloriesDouble)
        } else {
            calories = 0
            print("Warning: Could not decode calories as Int or Double")
        }
        
        if let proteinDouble = try? container.decode(Double.self, forKey: .protein) {
            protein = proteinDouble
        } else if let proteinInt = try? container.decode(Int.self, forKey: .protein) {
            protein = Double(proteinInt)
        } else {
            protein = 0.0
            print("Warning: Could not decode protein as Double or Int")
        }
        
        if let fatDouble = try? container.decode(Double.self, forKey: .fat) {
            fat = fatDouble
        } else if let fatInt = try? container.decode(Int.self, forKey: .fat) {
            fat = Double(fatInt)
        } else {
            fat = 0.0
            print("Warning: Could not decode fat as Double or Int")
        }
        
        if let carbsDouble = try? container.decode(Double.self, forKey: .carbs) {
            carbs = carbsDouble
        } else if let carbsInt = try? container.decode(Int.self, forKey: .carbs) {
            carbs = Double(carbsInt)
        } else {
            carbs = 0.0
            print("Warning: Could not decode carbs as Double or Int")
        }
        
        country = try container.decode(String.self, forKey: .country)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        
        // Handle date which could be in different formats
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                createdAt = fallbackFormatter.date(from: dateString)
            }
        } else {
            createdAt = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, calories, protein, fat, carbs, country, city
        case createdAt = "created_at"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Food, rhs: Food) -> Bool {
        lhs.id == rhs.id
    }
}

struct FoodListResponse: Codable {
    var success: Bool
    var data: [Food]
}

struct FoodSearchResponse: Codable {
    var success: Bool
    var data: [Food]
}

enum FoodPreference: String, Codable {
    case like = "Like"
    case dislike = "Dislike"
}

struct FoodPreferenceRequest: Codable {
    var userId: String
    var foodId: String
    var preference: FoodPreference
}

struct FoodNutritionResponse: Codable {
    var foodName: String
    var source: String
    var portion: Double
    var calories: Int
    var protein: Double
    var fat: Double
    var carbs: Double
    var originalPortionSize: Double
    var standardServing: String?
    var specifiedQuantity: String?
    var foodDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case source
        case portion
        case calories
        case protein
        case fat
        case carbs
        case originalPortionSize = "original_portion_size"
        case standardServing = "standard_serving"
        case specifiedQuantity = "specified_quantity"
        case foodDescription = "food_description"
    }
    
    // Add a custom initializer to handle potential type mismatches
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        foodName = try container.decode(String.self, forKey: .foodName)
        source = try container.decode(String.self, forKey: .source)
        standardServing = try container.decodeIfPresent(String.self, forKey: .standardServing)
        specifiedQuantity = try container.decodeIfPresent(String.self, forKey: .specifiedQuantity)
        foodDescription = try container.decodeIfPresent(String.self, forKey: .foodDescription)
        
        // Handle potential type mismatches for numeric values
        if let portionDouble = try? container.decode(Double.self, forKey: .portion) {
            portion = portionDouble
        } else if let portionInt = try? container.decode(Int.self, forKey: .portion) {
            portion = Double(portionInt)
        } else {
            portion = 100.0 // Default value
            print("Warning: Could not decode portion as Double or Int")
        }
        
        if let caloriesInt = try? container.decode(Int.self, forKey: .calories) {
            calories = caloriesInt
        } else if let caloriesDouble = try? container.decode(Double.self, forKey: .calories) {
            calories = Int(caloriesDouble)
        } else {
            calories = 0 // Default value
            print("Warning: Could not decode calories as Int or Double")
        }
        
        if let proteinDouble = try? container.decode(Double.self, forKey: .protein) {
            protein = proteinDouble
        } else if let proteinInt = try? container.decode(Int.self, forKey: .protein) {
            protein = Double(proteinInt)
        } else {
            protein = 0.0 // Default value
            print("Warning: Could not decode protein as Double or Int")
        }
        
        if let fatDouble = try? container.decode(Double.self, forKey: .fat) {
            fat = fatDouble
        } else if let fatInt = try? container.decode(Int.self, forKey: .fat) {
            fat = Double(fatInt)
        } else {
            fat = 0.0 // Default value
            print("Warning: Could not decode fat as Double or Int")
        }
        
        if let carbsDouble = try? container.decode(Double.self, forKey: .carbs) {
            carbs = carbsDouble
        } else if let carbsInt = try? container.decode(Int.self, forKey: .carbs) {
            carbs = Double(carbsInt)
        } else {
            carbs = 0.0 // Default value
            print("Warning: Could not decode carbs as Double or Int")
        }
        
        if let originalSizeDouble = try? container.decode(Double.self, forKey: .originalPortionSize) {
            originalPortionSize = originalSizeDouble
        } else if let originalSizeInt = try? container.decode(Int.self, forKey: .originalPortionSize) {
            originalPortionSize = Double(originalSizeInt)
        } else {
            originalPortionSize = 100.0 // Default value
            print("Warning: Could not decode originalPortionSize as Double or Int")
        }
    }
} 