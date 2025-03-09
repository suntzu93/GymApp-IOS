import Foundation

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

enum ActivityLevel: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum Goal: Codable, Equatable, Hashable {
    case gain
    case maintain
    case lose
    case custom(String)
    
    var rawValue: String {
        switch self {
        case .gain:
            return "Gain"
        case .maintain:
            return "Maintain"
        case .lose:
            return "Lose"
        case .custom(let value):
            return value
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value {
        case "Gain":
            self = .gain
        case "Maintain":
            self = .maintain
        case "Lose":
            self = .lose
        default:
            self = .custom(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    // Add hash(into:) method for Hashable conformance
    func hash(into hasher: inout Hasher) {
        switch self {
        case .gain:
            hasher.combine(0)
        case .maintain:
            hasher.combine(1)
        case .lose:
            hasher.combine(2)
        case .custom(let value):
            hasher.combine(3)
            hasher.combine(value)
        }
    }
    
    static var allCases: [Goal] {
        return [.gain, .maintain, .lose]
    }
    
    // Static method to create a Goal from a string
    static func fromString(_ string: String) -> Goal {
        switch string {
        case "Gain":
            return .gain
        case "Maintain":
            return .maintain
        case "Lose":
            return .lose
        default:
            return .custom(string)
        }
    }
}

enum Language: String, Codable, CaseIterable {
    case english = "en"
    case vietnamese = "vi"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .vietnamese:
            return "Vietnamese"
        }
    }
}

struct User: Codable, Identifiable {
    var id: String?
    var name: String
    var gender: Gender
    var age: Int
    var weight: Double
    var height: Double
    var activityLevel: ActivityLevel
    var goal: Goal
    var country: String
    var city: String
    var language: Language = .english // Default to English
    var dailyCalories: Int?
    var dailyProtein: Double?
    var dailyFat: Double?
    var dailyCarbs: Double?
    var createdAt: Date?
}

// Updated to match the new server response format
struct UserRegistrationResponse: Codable {
    var id: Int
    var name: String
    var gender: String
    var age: Int
    var weight: Double
    var height: Double
    var activityLevel: String
    var goal: String
    var country: String
    var city: String
    var language: String
    var dailyCalories: Int
    var dailyProtein: Double
    var dailyFat: Double
    var dailyCarbs: Double
    var createdAt: String
    
    // Helper method to convert to User model
    func toUser() -> User {
        return User(
            id: String(id),
            name: name,
            gender: Gender(rawValue: gender) ?? .male,
            age: age,
            weight: weight,
            height: height,
            activityLevel: ActivityLevel(rawValue: activityLevel) ?? .medium,
            goal: Goal.fromString(goal),
            country: country,
            city: city,
            language: Language(rawValue: language) ?? .english,
            dailyCalories: dailyCalories,
            dailyProtein: dailyProtein,
            dailyFat: dailyFat,
            dailyCarbs: dailyCarbs,
            createdAt: ISO8601DateFormatter().date(from: createdAt)
        )
    }
}

// Model for updating user information
struct UserUpdate: Codable {
    var name: String?
    var gender: Gender?
    var age: Int?
    var weight: Double?
    var height: Double?
    var activityLevel: ActivityLevel?
    var goal: Goal?
    var country: String?
    var city: String?
    var language: Language?
    
    // Create from User model
    static func fromUser(_ user: User) -> UserUpdate {
        return UserUpdate(
            name: user.name,
            gender: user.gender,
            age: user.age,
            weight: user.weight,
            height: user.height,
            activityLevel: user.activityLevel,
            goal: user.goal,
            country: user.country,
            city: user.city,
            language: user.language
        )
    }
} 