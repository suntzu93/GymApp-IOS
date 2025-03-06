import SwiftUI

@main
struct GymApp: App {
    @StateObject private var userManager = UserManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userManager)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        Group {
            if userManager.isLoggedIn {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "house.fill")
                        }
                    
                    FoodListView()
                        .tabItem {
                            Label("Foods", systemImage: "fork.knife")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
            } else {
                RegistrationView()
            }
        }
    }
}

struct FoodListView: View {
    @StateObject private var viewModel = FoodListViewModel()
    @EnvironmentObject var userManager: UserManager
    @State private var showingAddFoodSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search foods", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            if !newValue.isEmpty {
                                viewModel.searchFoods(query: newValue)
                            } else {
                                viewModel.loadFoods()
                            }
                        }
                }
                .padding()
                
                // Food list
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if viewModel.foods.isEmpty {
                    VStack {
                        Text("No foods available")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingAddFoodSheet = true
                        }) {
                            Text("Add New Food")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.foods) { food in
                            NavigationLink(destination: FoodDetailView(food: food)) {
                                FoodItemRow(food: food)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Food List")
            .navigationBarItems(trailing: Button(action: {
                showingAddFoodSheet = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddFoodSheet) {
                AddFoodView(onAddFood: { food in
                    viewModel.addFood(food: food)
                    showingAddFoodSheet = false
                })
            }
            .onAppear {
                if let user = userManager.currentUser {
                    viewModel.loadFoods(country: user.country, city: user.city)
                } else {
                    viewModel.loadFoods()
                }
            }
        }
    }
}

struct FoodItemRow: View {
    let food: FoodItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(food.name)
                    .fontWeight(.semibold)
                
                if let description = food.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(food.calories) kcal")
                    .fontWeight(.bold)
                
                Text("P: \(String(format: "%.1f", food.protein))g | F: \(String(format: "%.1f", food.fat))g | C: \(String(format: "%.1f", food.carbs))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FoodDetailView: View {
    let food: FoodItem
    @EnvironmentObject var userManager: UserManager
    @State private var showingAddToMealSheet = false
    @State private var preference: String?
    @State private var isSettingPreference = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Food info card
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let description = food.description, !description.isEmpty {
                        Text(description)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(food.calories) kcal per \(Int(food.portionSize))g")
                        .font(.headline)
                    
                    Divider()
                    
                    // Nutrition info
                    HStack {
                        NutrientInfoView(name: "Protein", value: food.protein, unit: "g", color: .blue)
                        NutrientInfoView(name: "Fat", value: food.fat, unit: "g", color: .yellow)
                        NutrientInfoView(name: "Carbs", value: food.carbs, unit: "g", color: .green)
                    }
                    
                    Divider()
                    
                    // Location info
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.secondary)
                        
                        Text("\(food.city ?? ""), \(food.country)")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingAddToMealSheet = true
                    }) {
                        Label("Add to Meal", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        Button(action: {
                            preference = "Like"
                            setPreference()
                        }) {
                            Label("Like", systemImage: "hand.thumbsup.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(preference == "Like" ? Color.green : Color(.systemGray5))
                                .foregroundColor(preference == "Like" ? .white : .primary)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            preference = "Dislike"
                            setPreference()
                        }) {
                            Label("Dislike", systemImage: "hand.thumbsdown.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(preference == "Dislike" ? Color.red : Color(.systemGray5))
                                .foregroundColor(preference == "Dislike" ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle("Food Details")
        .sheet(isPresented: $showingAddToMealSheet) {
            AddMealView(mealName: .constant("Breakfast"), onAddMeal: { foodItems in
                // We're only adding this one food item
                if let userId = userManager.currentUser?.id {
                    let mealViewModel = DashboardViewModel()
                    mealViewModel.addMeal(
                        userId: userId,
                        mealName: "Breakfast",
                        foodItems: [AddMealFoodItem(foodId: food.id, quantity: food.portionSize)]
                    )
                }
            })
        }
        .onAppear {
            loadPreference()
        }
        .overlay(
            Group {
                if isSettingPreference {
                    ProgressView()
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
        )
    }
    
    private func loadPreference() {
        guard let userId = userManager.currentUser?.id else { return }
        
        APIService.shared.getUserPreferences(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { preferences in
                    if let pref = preferences.first(where: { $0.foodId == food.id }) {
                        self.preference = pref.preference
                    }
                }
            )
            .store(in: &APIService.shared.cancellables)
    }
    
    private func setPreference() {
        guard let userId = userManager.currentUser?.id, let preference = preference else { return }
        
        isSettingPreference = true
        
        APIService.shared.setFoodPreference(userId: userId, foodId: food.id, preference: preference)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in
                    isSettingPreference = false
                },
                receiveValue: { _ in
                    isSettingPreference = false
                }
            )
            .store(in: &APIService.shared.cancellables)
    }
}

struct NutrientInfoView: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(String(format: "%.1f", value))\(unit)")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let user = userManager.currentUser {
                        // Profile header
                        VStack(alignment: .center, spacing: 10) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.blue)
                            
                            Text(user.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("\(user.city), \(user.country)")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        
                        // Personal info
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Personal Information")
                                .font(.headline)
                            
                            InfoRow(label: "Gender", value: user.gender)
                            InfoRow(label: "Age", value: "\(user.age) years")
                            InfoRow(label: "Weight", value: "\(String(format: "%.1f", user.weight)) kg")
                            InfoRow(label: "Height", value: "\(String(format: "%.1f", user.height)) cm")
                            InfoRow(label: "Language", value: user.language == "en" ? "English" : "Vietnamese")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        
                        // Fitness goals
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Fitness Goals")
                                .font(.headline)
                            
                            InfoRow(label: "Activity Level", value: user.activityLevel)
                            InfoRow(label: "Goal", value: user.goal)
                            
                            if let dailyCalories = user.dailyCalories {
                                InfoRow(label: "Daily Calories", value: "\(dailyCalories) kcal")
                            }
                            
                            if let dailyProtein = user.dailyProtein {
                                InfoRow(label: "Daily Protein", value: "\(String(format: "%.1f", dailyProtein)) g")
                            }
                            
                            if let dailyFat = user.dailyFat {
                                InfoRow(label: "Daily Fat", value: "\(String(format: "%.1f", dailyFat)) g")
                            }
                            
                            if let dailyCarbs = user.dailyCarbs {
                                InfoRow(label: "Daily Carbs", value: "\(String(format: "%.1f", dailyCarbs)) g")
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        
                        // Logout button
                        Button(action: {
                            userManager.logout()
                        }) {
                            Text("Logout")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding()
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct AddFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userManager: UserManager
    
    @State private var name = ""
    @State private var description = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var portionSize = "100"
    @State private var country = ""
    @State private var city = ""
    
    let onAddFood: (FoodItem) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Information")) {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $description)
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Fat (g)", text: $fat)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Portion Size (g)", text: $portionSize)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Location")) {
                    TextField("Country", text: $country)
                    TextField("City (optional)", text: $city)
                }
                
                Section {
                    Button(action: addFood) {
                        Text("Add Food")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Food")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                if let user = userManager.currentUser {
                    country = user.country
                    city = user.city
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !calories.isEmpty &&
        !protein.isEmpty &&
        !fat.isEmpty &&
        !carbs.isEmpty &&
        !portionSize.isEmpty &&
        !country.isEmpty &&
        Int(calories) != nil &&
        Double(protein) != nil &&
        Double(fat) != nil &&
        Double(carbs) != nil &&
        Double(portionSize) != nil
    }
    
    private func addFood() {
        guard let caloriesInt = Int(calories),
              let proteinDouble = Double(protein),
              let fatDouble = Double(fat),
              let carbsDouble = Double(carbs),
              let portionSizeDouble = Double(portionSize) else {
            return
        }
        
        let food = FoodItem(
            id: 0, // This will be ignored by the API
            name: name,
            description: description.isEmpty ? nil : description,
            calories: caloriesInt,
            protein: proteinDouble,
            fat: fatDouble,
            carbs: carbsDouble,
            portionSize: portionSizeDouble,
            country: country,
            city: city.isEmpty ? nil : city,
            createdAt: nil
        )
        
        onAddFood(food)
    }
} 