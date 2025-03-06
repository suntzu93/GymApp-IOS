import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userPresenter: UserPresenter
    @EnvironmentObject var mealPresenter: MealPresenter
    @State private var showingLanguagePicker = false
    @State private var selectedLanguage = AppLanguage.current
    
    var body: some View {
        NavigationView {
            List {
                if let user = userPresenter.user {
                    Section(header: Text("personal_info".localized)) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                
                                Text("\(user.age) years, \(Int(user.height)) cm, \(Int(user.weight)) kg")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(user.gender.rawValue), \(user.activityLevel.rawValue) activity")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Goal: \(user.goal.rawValue)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        HStack {
                            Text("country".localized)
                            Spacer()
                            Text(user.country)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("city".localized)
                            Spacer()
                            Text(user.city)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section(header: Text("daily_goal".localized)) {
                        HStack {
                            Text("calories".localized)
                            Spacer()
                            Text("\(user.dailyCalories ?? 0) kcal")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("protein".localized)
                            Spacer()
                            Text("\(Int(user.dailyProtein ?? 0)) g")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("fat".localized)
                            Spacer()
                            Text("\(Int(user.dailyFat ?? 0)) g")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("carbs".localized)
                            Spacer()
                            Text("\(Int(user.dailyCarbs ?? 0)) g")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("meal_history".localized)) {
                    if mealPresenter.mealHistory.isEmpty {
                        Text("no_meal_history".localized)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(mealPresenter.mealHistory.prefix(5)) { meal in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(meal.mealName)
                                        .font(.subheadline)
                                    
                                    Text(formatDate(from: meal.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(meal.totalCalories) kcal")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("settings".localized)) {
                    Button(action: {
                        showingLanguagePicker = true
                    }) {
                        HStack {
                            Text("language".localized)
                            Spacer()
                            Text(selectedLanguage.displayName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        userPresenter.logout()
                    }) {
                        HStack {
                            Text("logout".localized)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("profile_title".localized)
            .onAppear {
                if let userId = userPresenter.user?.id {
                    mealPresenter.fetchMealHistory(userId: userId)
                }
            }
            .actionSheet(isPresented: $showingLanguagePicker) {
                ActionSheet(
                    title: Text("language".localized),
                    buttons: AppLanguage.allCases.map { language in
                        .default(Text(language.displayName)) {
                            selectedLanguage = language
                            AppLanguage.current = language
                        }
                    } + [.cancel()]
                )
            }
        }
    }
    
    private func formatDate(from dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy h:mm a"
        
        if let date = dateFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserPresenter())
            .environmentObject(MealPresenter())
    }
} 