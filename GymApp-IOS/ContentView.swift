//
//  ContentView.swift
//  GymApp-IOS
//
//  Created by Lê Thanh on 6/3/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userPresenter: UserPresenter
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if userPresenter.isUserRegistered {
                TabView(selection: $selectedTab) {
                    DailyNutritionView()
                        .tabItem {
                            Label("daily_tab".localized, systemImage: "chart.pie.fill")
                        }
                        .tag(0)
                    
                    FoodListView()
                        .tabItem {
                            Label("food_tab".localized, systemImage: "list.bullet")
                        }
                        .tag(1)
                    
                    ProfileView()
                        .tabItem {
                            Label("profile_tab".localized, systemImage: "person.fill")
                        }
                        .tag(2)
                }
                .accentColor(.blue)
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            userPresenter.checkUserRegistration()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserPresenter())
        .environmentObject(MealPresenter())
        .environmentObject(FoodPresenter())
}
