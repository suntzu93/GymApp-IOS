import Foundation
import Combine
import KeychainSwift

class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let keychain = KeychainSwift()
    private let userIdKey = "userId"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadUserFromKeychain()
    }
    
    func registerUser(user: UserRegistration) {
        isLoading = true
        error = nil
        
        APIService.shared.registerUser(user: user)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                    self?.isLoggedIn = true
                    self?.saveUserToKeychain(userId: user.id)
                }
            )
            .store(in: &cancellables)
    }
    
    func loadUser(id: Int) {
        isLoading = true
        error = nil
        
        APIService.shared.getUser(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                        self?.logout()
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                    self?.isLoggedIn = true
                }
            )
            .store(in: &cancellables)
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        keychain.delete(userIdKey)
    }
    
    private func saveUserToKeychain(userId: Int) {
        keychain.set("\(userId)", forKey: userIdKey)
    }
    
    private func loadUserFromKeychain() {
        if let userIdString = keychain.get(userIdKey), let userId = Int(userIdString) {
            loadUser(id: userId)
        }
    }
} 