import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    
    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://gym.api.suntzu.dev"
    
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    private init() {
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    // MARK: - User API
    
    func registerUser(_ user: User) -> AnyPublisher<UserRegistrationResponse, APIError> {
        let endpoint = "\(baseURL)/users/register"
        
        return makePostRequest(to: endpoint, with: user)
    }
    
    func getUserInfo(userId: String) -> AnyPublisher<User, APIError> {
        let endpoint = "\(baseURL)/users/\(userId)"
        
        return makeGetRequest(to: endpoint)
            .tryMap { (response: [String: User]) -> User in
                guard let user = response["data"] else {
                    throw APIError.invalidResponse
                }
                return user
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Food API
    
    func getFoodList(country: String, city: String) -> AnyPublisher<FoodListResponse, APIError> {
        let encodedCountry = country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "\(baseURL)/food/list?country=\(encodedCountry)&city=\(encodedCity)"
        
        print("Fetching food list from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // Create a custom decoder without automatic snake_case conversion
        let customDecoder = JSONDecoder()
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { APIError.networkError($0) }
            .map { data, response -> Data in
                // Debug: Print the raw response data
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw food list response: \(jsonString)")
                }
                return data
            }
            .decode(type: [Food].self, decoder: customDecoder)
            .map { foods -> FoodListResponse in
                // Convert the array response to our expected format
                return FoodListResponse(success: true, data: foods)
            }
            .mapError { error in
                print("Food list decoding error: \(error)")
                if let error = error as? DecodingError {
                    print("Detailed food list decoding error: \(error.localizedDescription)")
                    return APIError.decodingError(error)
                } else {
                    return APIError.serverError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func searchFood(query: String) -> AnyPublisher<FoodSearchResponse, APIError> {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "\(baseURL)/food/search?q=\(encodedQuery)"
        
        print("Searching food with query: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // Create a custom decoder without automatic snake_case conversion
        let customDecoder = JSONDecoder()
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { APIError.networkError($0) }
            .map { data, response -> Data in
                // Debug: Print the raw response data
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw food search response: \(jsonString)")
                }
                return data
            }
            .decode(type: [Food].self, decoder: customDecoder)
            .map { foods -> FoodSearchResponse in
                // Convert the array response to our expected format
                return FoodSearchResponse(success: true, data: foods)
            }
            .mapError { error in
                print("Food search decoding error: \(error)")
                if let error = error as? DecodingError {
                    print("Detailed food search decoding error: \(error.localizedDescription)")
                    return APIError.decodingError(error)
                } else {
                    return APIError.serverError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func saveFoodPreference(userId: String, foodId: String, preference: FoodPreference) -> AnyPublisher<[String: Bool], APIError> {
        // Convert string IDs to integers
        let userIdInt = Int(userId) ?? 0
        let foodIdInt = Int(foodId) ?? 0
        
        // Build the endpoint with query parameters
        let endpoint = "\(baseURL)/ai/preferences?user_id=\(userIdInt)&food_id=\(foodIdInt)&preference=\(preference.rawValue)"
        
        print("Saving food preference: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // Create a POST request without a body
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create a custom decoder
        let customDecoder = JSONDecoder()
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .map { data, response -> Data in
                // Debug: Print the raw response data
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw preference response: \(jsonString)")
                }
                return data
            }
            .tryMap { data -> [String: Bool] in
                // Try to decode as a dictionary
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let message = json["message"] as? String {
                        print("Preference saved successfully: \(message)")
                        return ["success": true]
                    }
                }
                
                // If we can't decode as expected, check if it's an error response
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detail = errorJson["detail"] as? String {
                    print("Error saving preference: \(detail)")
                    throw APIError.serverError(detail)
                }
                
                // Default fallback
                return ["success": false]
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.serverError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Meal API
    
    func addMeal(request: MealRequest) -> AnyPublisher<MealResponse, APIError> {
        let endpoint = "\(baseURL)/meals/add"
        
        do {
            var requestDict: [String: Any] = [
                "user_id": request.userId,
                "meal_name": request.mealName,
                "total_calories": request.totalCalories,
                "total_protein": request.totalProtein,
                "total_fat": request.totalFat,
                "total_carbs": request.totalCarbs
            ]
            
            let itemsArray = request.items.map { item -> [String: Any] in
                return [
                    "food_id": item.foodId,
                    "quantity": item.quantity,
                    "portion_size": item.portionSize,
                    "calories": item.calories,
                    "protein": item.protein,
                    "fat": item.fat,
                    "carbs": item.carbs
                ]
            }
            
            requestDict["items"] = itemsArray
            
            let jsonData = try JSONSerialization.data(withJSONObject: requestDict)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Request to \(endpoint): \(jsonString)")
            }
            
            var urlRequest = URLRequest(url: URL(string: endpoint)!)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = jsonData
            
            // Create a custom decoder without automatic snake_case conversion
            let customDecoder = JSONDecoder()
            
            return URLSession.shared.dataTaskPublisher(for: urlRequest)
                .mapError { APIError.networkError($0) }
                .map { data, response -> Data in
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw response from \(endpoint): \(jsonString)")
                    }
                    return data
                }
                .decode(type: MealResponse.self, decoder: customDecoder)
                .mapError { error in
                    if let error = error as? DecodingError {
                        print("Decoding error for \(endpoint): \(error)")
                        return APIError.decodingError(error)
                    } else {
                        return APIError.serverError(error.localizedDescription)
                    }
                }
                .eraseToAnyPublisher()
        } catch {
            print("Error encoding meal request: \(error)")
            return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
        }
    }
    
    func getMealHistory(userId: String) -> AnyPublisher<MealHistoryResponse, APIError> {
        let userIdInt = Int(userId) ?? 0
        let endpoint = "\(baseURL)/meals/list/\(userIdInt)"
        
        print("Fetching meal history from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // Create a custom decoder without automatic snake_case conversion
        let customDecoder = JSONDecoder()
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { APIError.networkError($0) }
            .map { data, response -> Data in
                // Debug: Print the raw response data
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw meal history response: \(jsonString)")
                    
                    // Try to parse the JSON to see its structure
                    if let json = try? JSONSerialization.jsonObject(with: data) {
                        print("Parsed meal history JSON: \(json)")
                    }
                }
                return data
            }
            .tryMap { data -> MealHistoryResponse in
                // Try to decode as an array of MealHistoryItem
                do {
                    let meals = try customDecoder.decode([MealHistoryResponse.MealHistoryItem].self, from: data)
                    return MealHistoryResponse(success: true, data: meals)
                } catch {
                    print("Error decoding meal history as array: \(error)")
                    
                    // Try to decode as a response with success and data fields
                    do {
                        let response = try customDecoder.decode(MealHistoryResponse.self, from: data)
                        return response
                    } catch {
                        print("Error decoding meal history as response: \(error)")
                        
                        // If both fail, try to parse the JSON manually
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let errorDetail = json["detail"] as? String {
                                throw APIError.serverError(errorDetail)
                            }
                        }
                        
                        throw APIError.decodingError(error)
                    }
                }
            }
            .mapError { error in
                print("Meal history decoding error: \(error)")
                if let apiError = error as? APIError {
                    return apiError
                } else if let error = error as? DecodingError {
                    return APIError.decodingError(error)
                } else {
                    return APIError.serverError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func deleteMeal(mealId: String) -> AnyPublisher<[String: String], APIError> {
        let mealIdInt = Int(mealId) ?? 0
        let endpoint = "\(baseURL)/meals/\(mealIdInt)"
        
        print("Deleting meal with ID \(mealId) at endpoint: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            print("Invalid URL for deleting meal: \(endpoint)")
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { error -> APIError in
                print("Network error deleting meal: \(error.localizedDescription)")
                return APIError.networkError(error)
            }
            .map { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Delete meal response status code: \(httpResponse.statusCode)")
                }
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw delete meal response: \(jsonString)")
                }
                return data
            }
            .tryMap { data -> [String: String] in
                // Try to parse as JSON first
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Parsed delete meal response: \(json)")
                    
                    if let message = json["message"] as? String {
                        return ["message": message]
                    }
                    
                    if let detail = json["detail"] as? String {
                        throw APIError.serverError(detail)
                    }
                }
                
                // If we can't parse as JSON or the response is empty but successful
                if data.isEmpty {
                    print("Empty but successful response for delete meal")
                    return ["message": "Meal deleted successfully"]
                }
                
                // If we can't parse as JSON and the response is not empty
                if let responseString = String(data: data, encoding: .utf8) {
                    if responseString.contains("error") || responseString.contains("Error") {
                        throw APIError.serverError(responseString)
                    }
                    return ["message": responseString]
                }
                
                return ["message": "Meal deleted successfully"]
            }
            .mapError { error in
                print("Error in delete meal: \(error)")
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.serverError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - AI API
    
    func getFoodNutrition(foodName: String, userId: String, portion: Double = 100.0) -> AnyPublisher<FoodNutritionResponse, APIError> {
        let encodedFoodName = foodName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "\(baseURL)/ai/food-nutrition?food_name=\(encodedFoodName)&user_id=\(userId)&portion=\(portion)"
        
        print("Fetching food nutrition from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // Create a custom decoder without automatic snake_case conversion
        let customDecoder = JSONDecoder()
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { APIError.networkError($0) }
            .map { data, response -> Data in
                // Debug: Print the raw response data
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw food nutrition response: \(jsonString)")
                }
                return data
            }
            .decode(type: FoodNutritionResponse.self, decoder: customDecoder)
            .mapError { error in
                print("Food nutrition decoding error: \(error)")
                if let error = error as? DecodingError {
                    print("Detailed decoding error: \(error.localizedDescription)")
                    return APIError.decodingError(error)
                } else {
                    return APIError.serverError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getSuggestions(userId: String) -> AnyPublisher<AISuggestionResponse, APIError> {
        let endpoint = "\(baseURL)/ai/suggest?user_id=\(userId)"
        print("Fetching suggestions from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { APIError.networkError($0) }
            .map { data, response -> Data in
                // Debug: Print the raw response data
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw suggestions response: \(jsonString)")
                }
                return data
            }
            .decode(type: AISuggestionResponse.self, decoder: jsonDecoder)
            .mapError { error in
                print("Suggestions decoding error: \(error)")
                if let error = error as? DecodingError {
                    return APIError.decodingError(error)
                } else {
                    return APIError.serverError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Generic Network Methods
    
    private func makeGetRequest<T: Decodable>(to endpoint: String) -> AnyPublisher<T, APIError> {
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { APIError.networkError($0) }
            .map { $0.data }
            .decode(type: T.self, decoder: jsonDecoder)
            .mapError { error in
                if let error = error as? DecodingError {
                    return APIError.decodingError(error)
                } else {
                    return APIError.serverError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func makePostRequest<T: Encodable, U: Decodable>(to endpoint: String, with body: T) -> AnyPublisher<U, APIError> {
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try jsonEncoder.encode(body)
            
            // Debug: Print the request body
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Request to \(endpoint): \(jsonString)")
            }
            
            request.httpBody = jsonData
        } catch {
            print("Error encoding request body: \(error)")
            return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .map { data, response -> Data in
                // Debug: Print the raw response data
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw response from \(endpoint): \(jsonString)")
                }
                return data
            }
            .decode(type: U.self, decoder: jsonDecoder)
            .mapError { error in
                if let error = error as? DecodingError {
                    print("Decoding error for \(endpoint): \(error)")
                    return APIError.decodingError(error)
                } else {
                    return APIError.serverError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
} 