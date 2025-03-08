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

enum Goal: String, Codable, CaseIterable {
    case gain = "Gain"
    case maintain = "Maintain"
    case lose = "Lose"
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
            goal: Goal(rawValue: goal) ?? .maintain,
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