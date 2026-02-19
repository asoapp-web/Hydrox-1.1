//
//  MainTabView.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var waterManager = WaterManager()
    @State private var selectedTab = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                NavigationView {
                    CalculatorView()
                }
                .tabItem {
                    Label("Calculator", systemImage: "function")
                }
                .tag(1)
                
                NavigationView {
                    RemindersView()
                }
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
                .tag(2)
                
                NavigationView {
                    StatisticsView()
                }
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
                .tag(3)
            }
            .environmentObject(waterManager)
            .accentColor(.blue)
            .preferredColorScheme(getColorScheme())
            
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
            }
            
            // Request notification permissions on first launch
            NotificationManager.shared.requestAuthorization { _ in }
        }
        .onChange(of: showOnboarding) { newValue in
            if !newValue {
                hasSeenOnboarding = true
            }
        }
    }
    
    private func getColorScheme() -> ColorScheme? {
        switch waterManager.settings.appearanceMode {
        case .automatic:
            return nil  // Use system setting
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

