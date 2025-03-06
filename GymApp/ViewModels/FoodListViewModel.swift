import Foundation
import Combine

class FoodListViewModel: ObservableObject {
    @Published var foods: [FoodItem] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadFoods(country: String? = nil, city: String? = nil) {
        isLoading = true
        error = nil
        
        APIService.shared.getFoodList(country: country, city: city)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] foods in
                    self?.foods = foods
                }
            )
            .store(in: &cancellables)
    }
    
    func searchFoods(query: String) {
        isLoading = true
        error = nil
        
        APIService.shared.getFoodList(search: query)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] foods in
                    self?.foods = foods
                }
            )
            .store(in: &cancellables)
    }
    
    func addFood(food: FoodItem) {
        APIService.shared.addFood(food: food)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] food in
                    self?.loadFoods()
                }
            )
            .store(in: &cancellables)
    }
} 