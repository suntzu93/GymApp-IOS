import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var userManager: UserManager
    
    @State private var name = ""
    @State private var gender = "Male"
    @State private var age = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var activityLevel = "Medium"
    @State private var goal = "Maintain"
    @State private var country = ""
    @State private var city = ""
    @State private var language = "en"
    
    let genderOptions = ["Male", "Female"]
    let activityLevelOptions = ["Low", "Medium", "High"]
    let goalOptions = ["Gain", "Maintain", "Lose"]
    let languageOptions = [("English", "en"), ("Vietnamese", "vi")]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Height (cm)", text: $height)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Fitness Goals")) {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(activityLevelOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Goal", selection: $goal) {
                        ForEach(goalOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Location")) {
                    TextField("Country", text: $country)
                    TextField("City", text: $city)
                }
                
                Section(header: Text("Language Preference")) {
                    Picker("Language", selection: $language) {
                        ForEach(languageOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: registerUser) {
                        Text("Register")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid)
                }
                
                if userManager.isLoading {
                    Section {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                
                if let error = userManager.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Registration")
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !gender.isEmpty &&
        !age.isEmpty &&
        !weight.isEmpty &&
        !height.isEmpty &&
        !activityLevel.isEmpty &&
        !goal.isEmpty &&
        !country.isEmpty &&
        !city.isEmpty &&
        !language.isEmpty &&
        Int(age) != nil &&
        Double(weight) != nil &&
        Double(height) != nil
    }
    
    private func registerUser() {
        guard let ageInt = Int(age),
              let weightDouble = Double(weight),
              let heightDouble = Double(height) else {
            return
        }
        
        let user = UserRegistration(
            name: name,
            gender: gender,
            age: ageInt,
            weight: weightDouble,
            height: heightDouble,
            activityLevel: activityLevel,
            goal: goal,
            country: country,
            city: city,
            language: language
        )
        
        userManager.registerUser(user: user)
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
            .environmentObject(UserManager())
    }
} 