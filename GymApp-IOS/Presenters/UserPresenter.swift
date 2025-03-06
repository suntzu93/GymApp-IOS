import Foundation
import Combine

class UserPresenter: ObservableObject {
    @Published var user: User?
    @Published var isUserRegistered = false
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadUserFromDefaults()
    }
    
    func checkUserRegistration() {
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            isUserRegistered = true
            fetchUserInfo(userId: userId)
        } else {
            isUserRegistered = false
        }
    }
    
    private func loadUserFromDefaults() {
        if let userData = UserDefaults.standard.data(forKey: "userData"),
           let decodedUser = try? JSONDecoder().decode(User.self, from: userData) {
            self.user = decodedUser
            self.isUserRegistered = true
        }
    }
    
    private func saveUserToDefaults(_ user: User) {
        if let encodedData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedData, forKey: "userData")
        }
    }
    
    func registerUser(user: User) {
        isLoading = true
        error = nil
        
        print("Registering user: \(user.name)")
        
        apiService.registerUser(user)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    print("Registration error: \(error.message)")
                    self?.error = error.message
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                print("Registration response received with ID: \(response.id)")
                
                // Convert the response to our User model
                let updatedUser = response.toUser()
                
                print("User updated with ID: \(updatedUser.id ?? "unknown")")
                
                self.user = updatedUser
                self.isUserRegistered = true
                
                // Save user ID and data to UserDefaults
                if let userId = updatedUser.id {
                    UserDefaults.standard.set(userId, forKey: "userId")
                    self.saveUserToDefaults(updatedUser)
                } else {
                    print("Warning: User ID is nil after registration")
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchUserInfo(userId: String) {
        isLoading = true
        error = nil
        
        apiService.getUserInfo(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error.message
                }
            } receiveValue: { [weak self] user in
                self?.user = user
                self?.saveUserToDefaults(user)
            }
            .store(in: &cancellables)
    }
    
    func logout() {
        user = nil
        isUserRegistered = false
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userData")
    }
} 