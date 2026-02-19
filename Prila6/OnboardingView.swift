//
//  OnboardingView.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "drop.fill",
            title: "Welcome to Hydro Guru",
            description: "Your personal hydration companion. Track your water intake and stay healthy!",
            color: .blue
        ),
        OnboardingPage(
            icon: "calendar.badge.clock",
            title: "Daily Reminders",
            description: "Never forget to drink water with smart reminders throughout the day.",
            color: .green
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Track Your Progress",
            description: "Visualize your hydration journey with detailed statistics and charts.",
            color: .purple
        ),
        OnboardingPage(
            icon: "target",
            title: "Personalized Goals",
            description: "Calculate your perfect water intake based on your lifestyle.",
            color: .orange
        )
    ]
    
    var body: some View {
        VStack {
            // Skip Button
            HStack {
                Spacer()
                Button("Skip") {
                    showOnboarding = false
                }
                .foregroundColor(.gray)
                .padding()
            }
            
            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
            // Next/Get Started Button
            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    showOnboarding = false
                }
            }) {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pages[currentPage].color)
                    .cornerRadius(15)
            }
            .padding()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundColor(page.color)
            
            Text(page.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(showOnboarding: .constant(true))
    }
}

