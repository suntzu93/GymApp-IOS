import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @EnvironmentObject var userPresenter: UserPresenter
    @State private var name = ""
    @State private var gender = Gender.male
    @State private var age = 25
    @State private var height = 170.0
    @State private var weight = 70.0
    @State private var activityLevel = ActivityLevel.medium
    @State private var goal = Goal.maintain
    @State private var country = "Vietnam"
    @State private var city = "Hanoi"
    @State private var language = Language.english
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    TabView(selection: $currentStep) {
                        welcomeView
                            .tag(0)
                        
                        personalInfoView
                            .tag(1)
                        
                        goalsView
                            .tag(2)
                        
                        preferencesView
                            .tag(3)
                        
                        locationView
                            .tag(4)
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    navigationButtons
                }
                
                if userPresenter.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    LoadingView()
                }
            }
            .alert(item: Binding<AlertItem?>(
                get: { userPresenter.error != nil ? AlertItem(message: userPresenter.error!) : nil },
                set: { _ in userPresenter.error = nil }
            )) { alert in
                Alert(
                    title: Text("error".localized),
                    message: Text(alert.message),
                    dismissButton: .default(Text("ok".localized))
                )
            }
            .navigationTitle("onboarding_title".localized)
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            Text("onboarding_title".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("onboarding_subtitle".localized)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var personalInfoView: some View {
        Form {
            Section(header: Text("personal_info".localized)) {
                TextField("name".localized, text: $name)
                
                Picker("gender".localized, selection: $gender) {
                    Text("male".localized).tag(Gender.male)
                    Text("female".localized).tag(Gender.female)
                }
                .pickerStyle(.segmented)
                
                Stepper(value: $age, in: 16...100) {
                    HStack {
                        Text("age".localized)
                        Spacer()
                        Text("\(age)")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("height".localized)
                    Spacer()
                    Text("\(Int(height)) cm")
                        .foregroundColor(.secondary)
                }
                Slider(value: $height, in: 140...220, step: 1)
                
                HStack {
                    Text("weight".localized)
                    Spacer()
                    Text("\(Int(weight)) kg")
                        .foregroundColor(.secondary)
                }
                Slider(value: $weight, in: 40...150, step: 1)
            }
        }
    }
    
    private var goalsView: some View {
        Form {
            Section(header: Text("activity_level".localized)) {
                Picker("", selection: $activityLevel) {
                    Text("activity_low".localized).tag(ActivityLevel.low)
                    Text("activity_medium".localized).tag(ActivityLevel.medium)
                    Text("activity_high".localized).tag(ActivityLevel.high)
                }
                .pickerStyle(.segmented)
                
                switch activityLevel {
                case .low:
                    Text("Little or no exercise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .medium:
                    Text("Exercise 3-5 times a week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .high:
                    Text("Daily exercise or intense exercise 3-4 times a week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("goal".localized)) {
                Picker("", selection: $goal) {
                    Text("goal_lose".localized).tag(Goal.lose)
                    Text("goal_maintain".localized).tag(Goal.maintain)
                    Text("goal_gain".localized).tag(Goal.gain)
                }
                .pickerStyle(.segmented)
                
                switch goal {
                case .lose:
                    Text("Reduce body fat while maintaining muscle mass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .maintain:
                    Text("Maintain current weight and body composition")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .gain:
                    Text("Build muscle mass and strength")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .custom(let customGoal):
                    Text("Custom goal: \(customGoal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var preferencesView: some View {
        Form {
            Section(header: Text("Language")) {
                Picker("Select Language", selection: $language) {
                    ForEach(Language.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var locationView: some View {
        Form {
            Section(header: Text("location".localized)) {
                TextField("country".localized, text: $country)
                TextField("city".localized, text: $city)
                
                Button("Use Current Location") {
                    requestLocation()
                }
            }
            
            Section {
                Button("register_button".localized) {
                    registerUser()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding()
                }
            } else {
                Spacer()
            }
            
            Spacer()
            
            if currentStep < 4 {
                Button(action: {
                    withAnimation {
                        currentStep += 1
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private func requestLocation() {
        // In a real app, you would use CLLocationManager to get the user's location
        // For this example, we'll just set some default values
        country = "Vietnam"
        city = "Hanoi"
    }
    
    private func registerUser() {
        let user = User(
            id: nil,
            name: name,
            gender: gender,
            age: age,
            weight: weight,
            height: height,
            activityLevel: activityLevel,
            goal: goal,
            country: country,
            city: city,
            language: language
        )
        
        userPresenter.registerUser(user: user)
    }
}

struct AlertItem: Identifiable {
    var id = UUID()
    var message: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(UserPresenter())
    }
} 