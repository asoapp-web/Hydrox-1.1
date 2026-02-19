//
//  CalculatorView.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject var waterManager: WaterManager
    @State private var gender: UserProfile.Gender = .male
    @State private var weight: String = ""
    @State private var activityLevel: UserProfile.ActivityLevel = .moderate
    @State private var climate: UserProfile.Climate = .moderate
    @State private var calculatedGoal: Double = 0
    @State private var showingResult = false
    @State private var manualGoal: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "calculator.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Water Intake Calculator")
                        .font(.title2)
                        .bold()
                    
                    Text("Let's calculate your daily water goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Input Form
                VStack(spacing: 20) {
                    // Gender
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.headline)
                        
                        Picker("Gender", selection: $gender) {
                            ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg)")
                            .font(.headline)
                        
                        TextField("Enter your weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    // Activity Level
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity Level")
                            .font(.headline)
                        
                        Picker("Activity Level", selection: $activityLevel) {
                            ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Climate
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Climate")
                            .font(.headline)
                        
                        Picker("Climate", selection: $climate) {
                            ForEach(UserProfile.Climate.allCases, id: \.self) { climate in
                                Text(climate.rawValue).tag(climate)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(15)
                
                // Calculate Button
                Button(action: calculateGoal) {
                    HStack {
                        Image(systemName: "function")
                        Text("Calculate Daily Goal")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(weight.isEmpty)
                
                // Result
                if showingResult {
                    VStack(spacing: 15) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Your Daily Water Goal")
                            .font(.headline)
                        
                        Text("\(Int(calculatedGoal)) ml")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Text("≈ \(String(format: "%.1f", calculatedGoal / 1000)) liters")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        // Manual adjustment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Adjust Manually (optional)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("Custom goal in ml", text: $manualGoal)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button("Set") {
                                    if let custom = Double(manualGoal), custom > 0 {
                                        calculatedGoal = custom
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        
                        // Save Button
                        Button(action: saveGoal) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save This Goal")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.green.opacity(0.1))
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Current Goal Display
                if let currentGoal = waterManager.userProfile?.dailyGoal {
                    VStack(spacing: 8) {
                        Text("Current Goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(currentGoal)) ml")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Calculator")
        .onAppear(perform: loadCurrentProfile)
    }
    
    private func calculateGoal() {
        guard let weightValue = Double(weight), weightValue > 0 else { return }
        
        let goal = UserProfile.calculateDailyGoal(
            weight: weightValue,
            gender: gender,
            activityLevel: activityLevel,
            climate: climate
        )
        
        withAnimation(.spring()) {
            calculatedGoal = goal
            showingResult = true
        }
    }
    
    private func saveGoal() {
        guard let weightValue = Double(weight), weightValue > 0 else { return }
        
        waterManager.calculateAndSetGoal(
            weight: weightValue,
            gender: gender,
            activityLevel: activityLevel,
            climate: climate
        )
        
        // If manual goal was set, override
        if let custom = Double(manualGoal), custom > 0 {
            var profile = waterManager.userProfile!
            profile.dailyGoal = custom
            waterManager.updateProfile(profile)
        }
        
        // Show confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Optional: Show alert or toast
    }
    
    private func loadCurrentProfile() {
        if let profile = waterManager.userProfile {
            gender = profile.gender
            weight = String(Int(profile.weight))
            activityLevel = profile.activityLevel
            climate = profile.climate
        }
    }
}

struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CalculatorView()
                .environmentObject(WaterManager())
        }
    }
}

