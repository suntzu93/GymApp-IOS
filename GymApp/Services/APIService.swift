import Foundation
import Combine

class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:8000/api"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - User API
    
    func registerUser(user: UserRegistration) -> AnyPublisher<User, Error> {
        // Create URL with client_timestamp as a query parameter
        var urlComponents = URLComponents(string: "\(baseURL)/users/register")!
        urlComponents.queryItems = [URLQueryItem(name: "client_timestamp", value: user.clientTimestamp)]
        
        // Create a request body without client_timestamp
        struct UserRegistrationBody: Codable {
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
        
        let requestBody = UserRegistrationBody(
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
        
        return makePostRequest(url: urlComponents.url!, body: requestBody)
            .decode(type: User.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func getUser(id: Int) -> AnyPublisher<User, Error> {
        let url = URL(string: "\(baseURL)/users/\(id)")!
        
        return makeGetRequest(url: url)
            .decode(type: User.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - Food API
    
    func getFoodList(country: String? = nil, city: String? = nil, search: String? = nil) -> AnyPublisher<[FoodItem], Error> {
        var urlComponents = URLComponents(string: "\(baseURL)/food/list")!
        
        var queryItems: [URLQueryItem] = []
        if let country = country {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }
        if let city = city {
            queryItems.append(URLQueryItem(name: "city", value: city))
        }
        if let search = search {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        urlComponents.queryItems = queryItems
        
        return makeGetRequest(url: urlComponents.url!)
            .decode(type: [FoodItem].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func addFood(food: FoodItem) -> AnyPublisher<FoodItem, Error> {
        // Create URL with client_timestamp as a query parameter
        var urlComponents = URLComponents(string: "\(baseURL)/food/add")!
        if let timestamp = food.clientTimestamp {
            urlComponents.queryItems = [URLQueryItem(name: "client_timestamp", value: timestamp)]
        }
        
        // Create a request body without client_timestamp
        struct FoodItemBody: Codable {
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
            
            enum CodingKeys: String, CodingKey {
                case id, name, description, calories, protein, fat, carbs, country, city
                case portionSize = "portion_size"
            }
        }
        
        let requestBody = FoodItemBody(
            id: food.id,
            name: food.name,
            description: food.description,
            calories: food.calories,
            protein: food.protein,
            fat: food.fat,
            carbs: food.carbs,
            portionSize: food.portionSize,
            country: food.country,
            city: food.city
        )
        
        return makePostRequest(url: urlComponents.url!, body: requestBody)
            .decode(type: FoodItem.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func setFoodPreference(userId: Int, foodId: Int, preference: String) -> AnyPublisher<[String: String], Error> {
        // Create URL with client_timestamp as a query parameter
        var urlComponents = URLComponents(string: "\(baseURL)/food/preference")!
        urlComponents.queryItems = [URLQueryItem(name: "client_timestamp", value: getCurrentTimestamp())]
        
        // Create a request body without client_timestamp
        struct FoodPreferenceBody: Codable {
            let userId: Int
            let foodId: Int
            let preference: String
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case foodId = "food_id"
                case preference
            }
        }
        
        let requestBody = FoodPreferenceBody(
            userId: userId,
            foodId: foodId,
            preference: preference
        )
        
        return makePostRequest(url: urlComponents.url!, body: requestBody)
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func getUserPreferences(userId: Int) -> AnyPublisher<[FoodPreference], Error> {
        let url = URL(string: "\(baseURL)/food/preferences/\(userId)")!
        
        return makeGetRequest(url: url)
            .decode(type: [FoodPreference].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - Meal API
    
    func addMeal(meal: AddMealRequest) -> AnyPublisher<Meal, Error> {
        // Create URL with client_timestamp as a query parameter
        var urlComponents = URLComponents(string: "\(baseURL)/meals/add")!
        urlComponents.queryItems = [URLQueryItem(name: "client_timestamp", value: meal.clientTimestamp)]
        
        // Create a request body without client_timestamp
        struct MealRequestBody: Codable {
            let userId: Int
            let mealName: String
            let foodItems: [AddMealFoodItem]
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case mealName = "meal_name"
                case foodItems = "food_items"
            }
        }
        
        let requestBody = MealRequestBody(
            userId: meal.userId,
            mealName: meal.mealName,
            foodItems: meal.foodItems
        )
        
        return makePostRequest(url: urlComponents.url!, body: requestBody)
            .decode(type: Meal.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func getUserMeals(userId: Int, date: String? = nil) -> AnyPublisher<[Meal], Error> {
        var urlComponents = URLComponents(string: "\(baseURL)/meals/user/\(userId)")!
        
        var queryItems: [URLQueryItem] = []
        if let date = date {
            queryItems.append(URLQueryItem(name: "date_str", value: date))
        }
        urlComponents.queryItems = queryItems
        
        return makeGetRequest(url: urlComponents.url!)
            .decode(type: [Meal].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func getTodayNutrition(userId: Int) -> AnyPublisher<NutritionSummary, Error> {
        let url = URL(string: "\(baseURL)/meals/today/\(userId)")!
        
        return makeGetRequest(url: url)
            .decode(type: NutritionSummary.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func deleteMeal(mealId: Int, userId: Int) -> AnyPublisher<[String: String], Error> {
        // Create a direct URL string with all parameters
        let urlString = "\(baseURL)/meals/\(mealId)?user_id=\(userId)&client_timestamp=\(getCurrentTimestamp())"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                .eraseToAnyPublisher()
        }
        
        // Debug: Print the URL to verify it's constructed correctly
        print("DEBUG: Delete meal URL: \(url.absoluteString)")
        
        // Create the request directly
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debug: Print the request details
        print("DEBUG: Delete request URL: \(url.absoluteString)")
        print("DEBUG: Delete request method: \(request.httpMethod ?? "nil")")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { data, response in
                // Debug: Print the response details
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Delete response status: \(httpResponse.statusCode)")
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Delete response body: \(responseString)")
                }
                return data
            }
            .mapError { error -> Error in
                print("DEBUG: Delete network error: \(error)")
                return error
            }
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func deleteMealWithPost(mealId: Int, userId: Int) -> AnyPublisher<[String: String], Error> {
        // Create URL with client_timestamp as a query parameter
        var urlComponents = URLComponents(string: "\(baseURL)/meals/delete")!
        urlComponents.queryItems = [URLQueryItem(name: "client_timestamp", value: getCurrentTimestamp())]
        
        // Create a request body with meal_id and user_id
        struct DeleteMealBody: Codable {
            let mealId: Int
            let userId: Int
            
            enum CodingKeys: String, CodingKey {
                case mealId = "meal_id"
                case userId = "user_id"
            }
        }
        
        let requestBody = DeleteMealBody(
            mealId: mealId,
            userId: userId
        )
        
        // Debug: Print the request details
        print("DEBUG: Delete meal with POST - Meal ID: \(mealId), User ID: \(userId)")
        
        return makePostRequest(url: urlComponents.url!, body: requestBody)
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - AI API
    
    func getSuggestions(userId: Int) -> AnyPublisher<[FoodSuggestion], Error> {
        let urlComponents = URLComponents(string: "\(baseURL)/ai/suggest")!
        let url = urlComponents.url!.appendingQueryItem(name: "user_id", value: "\(userId)")
        
        return makeGetRequest(url: url)
            .decode(type: [FoodSuggestion].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func getSuggestionHistory(userId: Int) -> AnyPublisher<[FoodSuggestion], Error> {
        let url = URL(string: "\(baseURL)/ai/history/\(userId)")!
        
        return makeGetRequest(url: url)
            .decode(type: [FoodSuggestion].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func makeGetRequest(url: URL) -> AnyPublisher<Data, Error> {
        // Add client_timestamp to URL
        let urlWithTimestamp = url.appendingQueryItem(name: "client_timestamp", value: getCurrentTimestamp())
        
        var request = URLRequest(url: urlWithTimestamp)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    private func makePostRequest<T: Encodable>(url: URL, body: T) -> AnyPublisher<Data, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            let bodyData = try encoder.encode(body)
            request.httpBody = bodyData
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    private func makeDeleteRequest(url: URL) -> AnyPublisher<Data, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debug: Print the request details
        print("DEBUG: Delete request URL: \(url.absoluteString)")
        print("DEBUG: Delete request method: \(request.httpMethod ?? "nil")")
        print("DEBUG: Delete request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { data, response in
                // Debug: Print the response details
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: Delete response status: \(httpResponse.statusCode)")
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Delete response body: \(responseString)")
                }
                return data
            }
            .mapError { error -> Error in
                print("DEBUG: Delete network error: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }
    
    // Helper method to get current timestamp
    private func getCurrentTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        return timestamp
    }
}

// Extension to append query items to URL
extension URL {
    func appendingQueryItem(name: String, value: String) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        components.queryItems = queryItems
        return components.url!
    }
} 