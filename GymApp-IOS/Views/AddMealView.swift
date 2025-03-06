import SwiftUI
import UIKit
import Combine

struct AddMealView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userPresenter: UserPresenter
    @EnvironmentObject var mealPresenter: MealPresenter
    @EnvironmentObject var foodPresenter: FoodPresenter
    
    // Add optional parameter to track if coming from suggestions
    var fromSuggestions: Bool = false
    
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingFoodList = false
    @State private var showingCustomFoodSheet = false
    @State private var customFoodName = ""
    @State private var customFoodCalories = ""
    @State private var customFoodProtein = ""
    @State private var customFoodFat = ""
    @State private var customFoodCarbs = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Meal Type Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Type")
                                .font(.headline)
                            
                            Picker("Meal Type", selection: $selectedMealType) {
                                ForEach(MealType.allCases, id: \.self) { mealType in
                                    Text(mealType.rawValue.capitalized)
                                        .tag(mealType)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.horizontal)
                        
                        // Selected Foods Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected Foods")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if mealPresenter.selectedFoods.isEmpty {
                                EmptyStateView(
                                    title: "No Foods Selected",
                                    message: "Add foods to your meal by tapping the button below.",
                                    systemImage: "fork.knife"
                                )
                                .padding(.top)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(mealPresenter.selectedFoods) { food in
                                        SelectedFoodRow(food: food)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Add More Foods Button
                            Button(action: {
                                showingFoodList = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Add More Foods")
                                        .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 1)
                                        .background(Color(uiColor: .systemBackground))
                                )
                            }
                            .padding(.horizontal)
                            .padding(.top, 5)
                        }
                        
                        // Nutrition Summary
                        if !mealPresenter.selectedFoods.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Meal Nutrition")
                                    .font(.headline)
                                
                                let nutrition = mealPresenter.calculateMealNutrition()
                                
                                NutritionCard(
                                    title: selectedMealType.rawValue.capitalized,
                                    calories: nutrition.calories,
                                    protein: nutrition.protein,
                                    fat: nutrition.fat,
                                    carbs: nutrition.carbs,
                                    backgroundColor: Color(uiColor: .secondarySystemBackground)
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Add Custom Food Button
                        Button(action: {
                            showingCustomFoodSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                Text("Add Custom Food")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Submit Button
                        if !mealPresenter.selectedFoods.isEmpty {
                            Button(action: {
                                if let userId = userPresenter.user?.id {
                                    mealPresenter.submitMeal(userId: userId, mealType: selectedMealType, fromSuggestions: fromSuggestions)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                Text("Add to Daily Meals")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                if mealPresenter.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    LoadingView()
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    mealPresenter.clearMeal()
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingFoodList) {
                FoodListView()
            }
            .sheet(isPresented: $showingCustomFoodSheet) {
                CustomFoodView(isPresented: $showingCustomFoodSheet)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MealAddedSuccessfully"))) { _ in
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct SelectedFoodRow: View {
    @EnvironmentObject var mealPresenter: MealPresenter
    let food: Food
    @State private var quantity: String = "100"
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(food.calories) kcal per 100g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                TextField("g", text: $quantity)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    .padding(6)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(8)
                    .onChange(of: quantity) { newValue in
                    if let doubleValue = Double(newValue) {
                        mealPresenter.updateQuantity(for: food, quantity: doubleValue)
                    }
                }
                
                Text("g")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    mealPresenter.removeFoodFromMeal(food)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 22))
                }
            }
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            if let existingQuantity = mealPresenter.quantities[food.id] {
                quantity = String(format: "%.0f", existingQuantity)
            }
        }
    }
}

struct CustomFoodView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var mealPresenter: MealPresenter
    @EnvironmentObject var userPresenter: UserPresenter
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var nutritionLoaded = false
    
    private let apiService = APIService.shared
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Food Details")) {
                        HStack {
                            TextField("Food Name", text: $foodName)
                            
                            if !foodName.isEmpty {
                                Button(action: {
                                    loadFoodNutrition()
                                }) {
                                    Text("Get Info")
                                        .foregroundColor(.blue)
                                }
                                .disabled(isLoading || foodName.isEmpty)
                            }
                        }
                        
                        HStack {
                            Text("Calories:")
                            Spacer()
                            TextField("kcal", text: $calories)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .disabled(isLoading)
                        }
                        
                        HStack {
                            Text("Protein:")
                            Spacer()
                            TextField("g", text: $protein)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .disabled(isLoading)
                        }
                        
                        HStack {
                            Text("Fat:")
                            Spacer()
                            TextField("g", text: $fat)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .disabled(isLoading)
                        }
                        
                        HStack {
                            Text("Carbs:")
                            Spacer()
                            TextField("g", text: $carbs)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .disabled(isLoading)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            addCustomFood()
                        }) {
                            Text("Add to Meal")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled(isLoading || foodName.isEmpty)
                    }
                }
                
                if isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    LoadingView()
                }
            }
            .navigationTitle("Custom Food")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func loadFoodNutrition() {
        guard !foodName.isEmpty else { return }
        guard let userId = userPresenter.user?.id else {
            errorMessage = "User information not available"
            showError = true
            return
        }
        
        isLoading = true
        
        apiService.getFoodNutrition(foodName: foodName, userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                
                if case .failure(let error) = completion {
                    errorMessage = error.message
                    showError = true
                }
            } receiveValue: { response in
                // Fill in the nutrition values
                calories = "\(response.calories)"
                protein = String(format: "%.1f", response.protein)
                fat = String(format: "%.1f", response.fat)
                carbs = String(format: "%.1f", response.carbs)
                nutritionLoaded = true
            }
            .store(in: &cancellables)
    }
    
    private func addCustomFood() {
        // Validate inputs
        guard !foodName.isEmpty else {
            errorMessage = "Please enter a food name"
            showError = true
            return
        }
        
        guard let caloriesValue = Int(calories), caloriesValue > 0 else {
            errorMessage = "Please enter a valid calorie value"
            showError = true
            return
        }
        
        guard let proteinValue = Double(protein), proteinValue >= 0 else {
            errorMessage = "Please enter a valid protein value"
            showError = true
            return
        }
        
        guard let fatValue = Double(fat), fatValue >= 0 else {
            errorMessage = "Please enter a valid fat value"
            showError = true
            return
        }
        
        guard let carbsValue = Double(carbs), carbsValue >= 0 else {
            errorMessage = "Please enter a valid carbs value"
            showError = true
            return
        }
        
        // Create custom food
        let customFood = Food(
            id: UUID().uuidString,
            name: foodName,
            calories: caloriesValue,
            protein: proteinValue,
            fat: fatValue,
            carbs: carbsValue,
            country: "Custom",
            city: "Custom"
        )
        
        // Add to meal
        mealPresenter.addFoodToMeal(customFood)
        
        // Close sheet
        isPresented = false
    }
}

struct AddMealView_Previews: PreviewProvider {
    static var previews: some View {
        AddMealView()
            .environmentObject(UserPresenter())
            .environmentObject(MealPresenter())
            .environmentObject(FoodPresenter())
    }
} 
