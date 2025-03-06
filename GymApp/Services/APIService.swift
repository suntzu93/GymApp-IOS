import Foundation
import Combine

class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:8000/api"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - User API
    
    func registerUser(user: UserRegistration) -> AnyPublisher<User, Error> {
        let url = URL(string: "\(baseURL)/users/register")!
        
        return makePostRequest(url: url, body: user)
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
        let url = URL(string: "\(baseURL)/food/add")!
        
        return makePostRequest(url: url, body: food)
            .decode(type: FoodItem.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func setFoodPreference(userId: Int, foodId: Int, preference: String) -> AnyPublisher<[String: String], Error> {
        let url = URL(string: "\(baseURL)/food/preference")!
        let body = ["user_id": userId, "food_id": foodId, "preference": preference]
        
        return makePostRequest(url: url, body: body)
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
        let url = URL(string: "\(baseURL)/meals/add")!
        
        return makePostRequest(url: url, body: meal)
            .decode(type: Meal.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func getUserMeals(userId: Int, date: String? = nil) -> AnyPublisher<[Meal], Error> {
        var urlComponents = URLComponents(string: "\(baseURL)/meals/user/\(userId)")!
        
        if let date = date {
            urlComponents.queryItems = [URLQueryItem(name: "date_str", value: date)]
        }
        
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
    
    func deleteMeal(mealId: Int) -> AnyPublisher<[String: String], Error> {
        let url = URL(string: "\(baseURL)/meals/\(mealId)")!
        
        return makeDeleteRequest(url: url)
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
        var request = URLRequest(url: url)
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
            request.httpBody = try JSONEncoder().encode(body)
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
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
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