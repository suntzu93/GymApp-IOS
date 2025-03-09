import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userPresenter: UserPresenter
    
    @State private var name: String = ""
    @State private var gender: Gender = .male
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var activityLevel: ActivityLevel = .medium
    @State private var goalText: String = ""
    @State private var country: String = ""
    @State private var city: String = ""
    
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIsSuccess = true
    
    var body: some View {
        ZStack {
            NavigationView {
                Form {
                    Section(header: Text("Personal Information")) {
                        TextField("Name", text: $name)
                        
                        Picker("Gender", selection: $gender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        
                        HStack {
                            Text("Age")
                            Spacer()
                            TextField("Age", text: $age)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Text("Weight (kg)")
                            Spacer()
                            TextField("Weight", text: $weight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Text("Height (cm)")
                            Spacer()
                            TextField("Height", text: $height)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                    
                    Section(header: Text("Fitness Goals")) {
                        Picker("Activity Level", selection: $activityLevel) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        
                        HStack {
                            Text("Goal")
                            Spacer()
                            TextField("Enter your goal", text: $goalText)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Section(header: Text("Location")) {
                        TextField("Country", text: $country)
                        TextField("City", text: $city)
                    }
                    
                    Section {
                        Button(action: saveChanges) {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.blue)
                        }
                        .disabled(userPresenter.isLoading)
                    }
                }
                .navigationTitle("Edit Profile")
                .navigationBarItems(trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
                .onAppear(perform: loadUserData)
            }
            
            // Loading overlay
            if userPresenter.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                LoadingView()
            }
            
            // Toast message
            if showToast {
                VStack {
                    Spacer()
                    
                    ToastView(
                        message: toastMessage,
                        isSuccess: toastIsSuccess,
                        onDismiss: {
                            showToast = false
                        }
                    )
                    .padding(.bottom, 20)
                    .onAppear {
                        // Auto-dismiss the toast after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showToast = false
                                
                                // Dismiss the view after the toast is shown
                                if toastIsSuccess {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: showToast)
            }
        }
    }
    
    private func loadUserData() {
        if let user = userPresenter.user {
            name = user.name
            gender = user.gender
            age = String(user.age)
            weight = String(format: "%.1f", user.weight)
            height = String(format: "%.1f", user.height)
            activityLevel = user.activityLevel
            goalText = user.goal.rawValue
            country = user.country
            city = user.city
        }
    }
    
    private func saveChanges() {
        guard !goalText.isEmpty else {
            toastMessage = "Please enter your goal"
            toastIsSuccess = false
            showToast = true
            return
        }
        
        guard let ageInt = Int(age),
              let weightDouble = Double(weight),
              let heightDouble = Double(height) else {
            toastMessage = "Please enter valid values for age, weight, and height"
            toastIsSuccess = false
            showToast = true
            return
        }
        
        // Determine the goal based on the text
        let goal: Goal
        switch goalText.lowercased() {
        case "gain":
            goal = .gain
        case "maintain":
            goal = .maintain
        case "lose":
            goal = .lose
        default:
            goal = .custom(goalText)
        }
        
        let update = UserUpdate(
            name: name,
            gender: gender,
            age: ageInt,
            weight: weightDouble,
            height: heightDouble,
            activityLevel: activityLevel,
            goal: goal,
            country: country,
            city: city
        )
        
        userPresenter.updateUser(update: update) { success in
            if success {
                // Show success toast
                toastMessage = "Profile updated successfully"
                toastIsSuccess = true
                showToast = true
                
                // Reload user data from server
                if let userId = userPresenter.user?.id {
                    userPresenter.fetchUserInfo(userId: userId)
                }
            } else {
                // Show error toast
                toastMessage = userPresenter.error ?? "Failed to update profile"
                toastIsSuccess = false
                showToast = true
            }
        }
    }
} 