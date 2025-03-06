import SwiftUI

struct AddMealView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = FoodListViewModel()
    @Binding var mealName: String
    let onAddMeal: ([AddMealFoodItem]) -> Void
    
    @State private var selectedFoods: [FoodItem] = []
    @State private var quantities: [Int: Double] = [:]
    @State private var searchText = ""
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Meal type picker
                Picker("Meal Type", selection: $mealName) {
                    ForEach(mealTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
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
                .padding(.horizontal)
                
                // Selected foods
                if !selectedFoods.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Selected Foods")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        List {
                            ForEach(selectedFoods) { food in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(food.name)
                                            .fontWeight(.semibold)
                                        
                                        Text("\(food.calories) kcal per \(Int(food.portionSize))g")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Quantity stepper
                                    Stepper(
                                        value: Binding(
                                            get: { self.quantities[food.id] ?? food.portionSize },
                                            set: { self.quantities[food.id] = $0 }
                                        ),
                                        in: 10...500,
                                        step: 10
                                    ) {
                                        Text("\(Int(quantities[food.id] ?? food.portionSize))g")
                                    }
                                    .frame(width: 150)
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let food = selectedFoods[index]
                                    quantities.removeValue(forKey: food.id)
                                }
                                selectedFoods.remove(atOffsets: indexSet)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
                // Available foods
                VStack(alignment: .leading) {
                    Text("Available Foods")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if viewModel.foods.isEmpty {
                        Text("No foods available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        List {
                            ForEach(viewModel.foods) { food in
                                if !selectedFoods.contains(where: { $0.id == food.id }) {
                                    Button(action: {
                                        selectedFoods.append(food)
                                        quantities[food.id] = food.portionSize
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(food.name)
                                                    .fontWeight(.semibold)
                                                
                                                Text("\(food.calories) kcal per \(Int(food.portionSize))g")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Add Meal")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let foodItems = selectedFoods.map { food in
                        AddMealFoodItem(foodId: food.id, quantity: quantities[food.id] ?? food.portionSize)
                    }
                    onAddMeal(foodItems)
                }
                .disabled(selectedFoods.isEmpty)
            )
            .onAppear {
                viewModel.loadFoods()
            }
        }
    }
}

struct AddMealView_Previews: PreviewProvider {
    static var previews: some View {
        AddMealView(mealName: .constant("Breakfast"), onAddMeal: { _ in })
    }
} 