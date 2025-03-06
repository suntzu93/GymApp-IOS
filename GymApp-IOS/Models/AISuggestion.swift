import Foundation

struct AISuggestion: Codable, Identifiable {
    var id: Int
    var userId: Int?  // Changed from String? to Int? to match the server response
    var suggestedFood: String
    var calories: Int
    var protein: Double
    var fat: Double
    var carbs: Double
    var portionSize: Double?  // Make optional in case it's missing and use Double instead of Int
    var createdAt: String?  // Make optional in case it's missing
    
    var identifier: String {
        return String(id)
    }
    
    var name: String {
        return suggestedFood
    }
}

// The server returns an array of AISuggestion objects directly
typealias AISuggestionResponse = [AISuggestion] 