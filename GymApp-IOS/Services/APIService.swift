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
    
    // Helper method to get current timestamp in ISO 8601 format without milliseconds
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    // MARK: - User API
    
    func registerUser(_ user: User) -> AnyPublisher<UserRegistrationResponse, APIError> {
        let endpoint = "\(baseURL)/users/register"
        
        return makePostRequest(to: endpoint, with: user)
    }
    
    func getUserInfo(userId: String) -> AnyPublisher<User, APIError> {
        let timestamp = getCurrentTimestamp()
        let endpoint = "\(baseURL)/users/\(userId)?client_timestamp=\(timestamp)"
        
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
    
    func updateUser(userId: String, update: UserUpdate) -> AnyPublisher<User, APIError> {
        let timestamp = getCurrentTimestamp()
        let endpoint = "\(baseURL)/users/\(userId)?client_timestamp=\(timestamp)"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try jsonEncoder.encode(update)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Update user request: \(jsonString)")
            }
        } catch {
            return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .map { data, response -> Data in
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw update user response: \(jsonString)")
                }
                return data
            }
            .tryMap { data -> User in
                // Try to decode the response directly
                do {
                    // First try to decode as UserRegistrationResponse
                    let response = try JSONDecoder().decode(UserRegistrationResponse.self, from: data)
                    return response.toUser()
                } catch {
                    print("Failed to decode as UserRegistrationResponse: \(error)")
                    
                    // If that fails, try to decode directly as User
                    do {
                        return try JSONDecoder().decode(User.self, from: data)
                    } catch {
                        print("Failed to decode as User: \(error)")
                        
                        // If both fail, try to manually create a User from the JSON
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            // Extract values from JSON
                            let id = String(describing: json["id"] ?? "")
                            let name = json["name"] as? String ?? ""
                            let genderStr = json["gender"] as? String ?? "Male"
                            let age = json["age"] as? Int ?? 0
                            let weight = json["weight"] as? Double ?? 0.0
                            let height = json["height"] as? Double ?? 0.0
                            let activityLevelStr = json["activity_level"] as? String ?? "Medium"
                            let goalStr = json["goal"] as? String ?? "Maintain"
                            let country = json["country"] as? String ?? ""
                            let city = json["city"] as? String ?? ""
                            let languageStr = json["language"] as? String ?? "en"
                            let dailyCalories = json["daily_calories"] as? Int ?? 0
                            let dailyProtein = json["daily_protein"] as? Double ?? 0.0
                            let dailyFat = json["daily_fat"] as? Double ?? 0.0
                            let dailyCarbs = json["daily_carbs"] as? Double ?? 0.0
                            
                            // Create User object
                            return User(
                                id: id,
                                name: name,
                                gender: Gender(rawValue: genderStr) ?? .male,
                                age: age,
                                weight: weight,
                                height: height,
                                activityLevel: ActivityLevel(rawValue: activityLevelStr) ?? .medium,
                                goal: Goal.fromString(goalStr),
                                country: country,
                                city: city,
                                language: Language(rawValue: languageStr) ?? .english,
                                dailyCalories: dailyCalories,
                                dailyProtein: dailyProtein,
                                dailyFat: dailyFat,
                                dailyCarbs: dailyCarbs
                            )
                        }
                        
                        throw APIError.decodingError(error)
                    }
                }
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.serverError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Food API
    
    func getFoodList(country: String, city: String) -> AnyPublisher<FoodListResponse, APIError> {
        let timestamp = getCurrentTimestamp()
        let encodedCountry = country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "\(baseURL)/food/list?country=\(encodedCountry)&city=\(encodedCity)&client_timestamp=\(timestamp)"
        
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
    
    func searchFood(query: String, country: String = "Vietnam", city: String = "Hanoi", limit: Int = 10) -> AnyPublisher<FoodListResponse, APIError> {
        let timestamp = getCurrentTimestamp()
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedCountry = country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "\(baseURL)/food/list?country=\(encodedCountry)&city=\(encodedCity)&search=\(encodedQuery)&limit=\(limit)&client_timestamp=\(timestamp)"
        
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
            .map { foods -> FoodListResponse in
                // Convert the array response to our expected format
                return FoodListResponse(success: true, data: foods)
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
        let timestamp = getCurrentTimestamp()
        let userIdInt = Int(userId) ?? 0
        let foodIdInt = Int(foodId) ?? 0
        
        // Build the endpoint with query parameters
        let endpoint = "\(baseURL)/ai/preferences?user_id=\(userIdInt)&food_id=\(foodIdInt)&preference=\(preference.rawValue)&client_timestamp=\(timestamp)"
        
        print("Saving food preference: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // Create a POST request without a body
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        
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
    
    func getMealDetails(mealId: String, userId: String) -> AnyPublisher<MealDetailResponse, APIError> {
        let timestamp = getCurrentTimestamp()
        let mealIdInt = Int(mealId) ?? 0
        let userIdInt = Int(userId) ?? 0
        let endpoint = "\(baseURL)/meals/\(mealIdInt)?user_id=\(userIdInt)&client_timestamp=\(timestamp)"
        
        print("Fetching meal details from: \(endpoint)")
        
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
                    print("Raw meal details response: \(jsonString)")
                }
                return data
            }
            .decode(type: MealDetailResponse.self, decoder: customDecoder)
            .mapError { error in
                print("Meal details decoding error: \(error)")
                if let error = error as? DecodingError {
                    print("Detailed decoding error: \(error.localizedDescription)")
                    return APIError.decodingError(error)
                } else {
                    return APIError.serverError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func addMeal(request: MealRequest) -> AnyPublisher<MealResponse, APIError> {
        let timestamp = getCurrentTimestamp()
        let endpoint = "\(baseURL)/meals/add?client_timestamp=\(timestamp)"
        
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
                    "carbs": item.carbs,
                    "food_name": item.foodName ?? ""
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
        let timestamp = getCurrentTimestamp()
        let userIdInt = Int(userId) ?? 0
        let endpoint = "\(baseURL)/meals/list/\(userIdInt)?client_timestamp=\(timestamp)"
        
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
    
    func deleteMeal(mealId: String, userId: String) -> AnyPublisher<[String: String], APIError> {
        let timestamp = getCurrentTimestamp()
        let mealIdInt = Int(mealId) ?? 0
        let userIdInt = Int(userId) ?? 0
        let endpoint = "\(baseURL)/meals/\(mealIdInt)?user_id=\(userIdInt)&client_timestamp=\(timestamp)"
        
        print("Deleting meal with ID \(mealId) for user \(userId) at endpoint: \(endpoint)")
        
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
        let timestamp = getCurrentTimestamp()
        let encodedFoodName = foodName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "\(baseURL)/ai/food-nutrition?food_name=\(encodedFoodName)&user_id=\(userId)&portion=\(portion)&client_timestamp=\(timestamp)"
        
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
        let timestamp = getCurrentTimestamp()
        let endpoint = "\(baseURL)/ai/suggest?user_id=\(userId)&client_timestamp=\(timestamp)"
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
    
    // MARK: - Meal Plan API
    
    func getDailyMealPlan(userId: String) -> AnyPublisher<MealPlanResponse, APIError> {
        let timestamp = getCurrentTimestamp()
        let endpoint = "\(baseURL)/meals/daily-plan/\(userId)?client_timestamp=\(timestamp)"
        
        print("Fetching daily meal plan from: \(endpoint)")
        
        return makeGetRequest(to: endpoint)
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
        let timestamp = getCurrentTimestamp()
        var finalEndpoint = endpoint
        
        // Add client_timestamp to the endpoint URL
        if let url = URL(string: endpoint), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            var queryItems = components.queryItems ?? []
            queryItems.append(URLQueryItem(name: "client_timestamp", value: timestamp))
            components.queryItems = queryItems
            
            if let updatedURL = components.url {
                finalEndpoint = updatedURL.absoluteString
            }
        }
        
        guard let url = URL(string: finalEndpoint) else {
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
