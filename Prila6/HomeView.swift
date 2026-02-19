//
//  HomeView.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var waterManager: WaterManager
    @State private var showingAddWater = false
    @State private var animateWater = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Daily Quote
                    quoteSection
                    
                    // Water Progress Visualization
                    waterProgressSection
                    
                    // Quick Add Buttons
                    quickAddButtons
                    
                    // Today's History
                    todayHistorySection
                }
                .padding()
            }
            .navigationTitle("Hydro Guru")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
    
    // MARK: - Quote Section
    private var quoteSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "quote.bubble.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(DailyQuote.dailyQuote())
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    // MARK: - Water Progress Section
    private var waterProgressSection: some View {
        VStack(spacing: 15) {
            ZStack {
                // Background bottle
                bottleShape
                    .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                    .frame(width: 150, height: 250)
                
                // Filled water
                bottleShape
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 150, height: 250)
                    .mask(
                        GeometryReader { geometry in
                            Rectangle()
                                .frame(height: geometry.size.height * waterManager.getProgress())
                                .offset(y: geometry.size.height * (1 - waterManager.getProgress()))
                        }
                    )
                    .scaleEffect(animateWater ? 1.05 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateWater)
                
                // Wave effect
                WaveShape(progress: waterManager.getProgress(), waveHeight: 10)
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 150, height: 250)
                    .mask(bottleShape)
            }
            
            // Stats
            VStack(spacing: 5) {
                Text("\(Int(waterManager.todayTotal)) ml")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.blue)
                
                if let goal = waterManager.userProfile?.dailyGoal {
                    Text("of \(Int(goal)) ml")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(waterManager.getProgress() * 100))% Complete")
                        .font(.headline)
                        .foregroundColor(.blue)
                } else {
                    Text("Set your goal in Calculator")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
    }
    
    private var bottleShape: some Shape {
        RoundedRectangle(cornerRadius: 20)
    }
    
    // MARK: - Quick Add Buttons
    private var quickAddButtons: some View {
        VStack(spacing: 12) {
            Text("Add Water")
                .font(.headline)
            
            HStack(spacing: 15) {
                QuickAddButton(amount: 100, icon: "drop.fill") {
                    addWater(amount: 100)
                }
                
                QuickAddButton(amount: 250, icon: "cup.and.saucer.fill") {
                    addWater(amount: 250)
                }
                
                QuickAddButton(amount: 500, icon: "waterbottle.fill") {
                    addWater(amount: 500)
                }
            }
            
            Button(action: {
                showingAddWater = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Custom Amount")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingAddWater) {
            CustomAmountView(isPresented: $showingAddWater)
                .environmentObject(waterManager)
        }
    }
    
    // MARK: - Today's History
    private var todayHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's History")
                .font(.headline)
            
            let entries = waterManager.getTodayEntries()
            
            if entries.isEmpty {
                Text("No water logged yet today")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(entries) { entry in
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        
                        Text("\(Int(entry.amount)) ml")
                            .font(.body)
                        
                        Spacer()
                        
                        Text(entry.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            withAnimation {
                                waterManager.deleteEntry(entry)
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func addWater(amount: Double) {
        withAnimation(.spring()) {
            waterManager.addWater(amount: amount)
            animateWater = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateWater = false
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Quick Add Button
struct QuickAddButton: View {
    let amount: Int
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text("\(amount)ml")
                    .font(.caption)
                    .bold()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(15)
        }
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var progress: Double
    var waveHeight: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveY = rect.height * (1 - progress)
        let amplitude = waveHeight
        
        path.move(to: CGPoint(x: 0, y: waveY))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 4)
            let y = waveY + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Custom Amount View
struct CustomAmountView: View {
    @EnvironmentObject var waterManager: WaterManager
    @Binding var isPresented: Bool
    @State private var customAmount: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Enter Custom Amount")
                    .font(.title2)
                    .bold()
                
                TextField("Amount in ml", text: $customAmount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: {
                    if let amount = Double(customAmount), amount > 0 {
                        waterManager.addWater(amount: amount)
                        isPresented = false
                    }
                }) {
                    Text("Add Water")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .disabled(customAmount.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(WaterManager())
    }
}

