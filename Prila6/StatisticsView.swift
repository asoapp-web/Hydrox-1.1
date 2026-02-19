//
//  StatisticsView.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var waterManager: WaterManager
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Your Progress")
                        .font(.title2)
                        .bold()
                    
                    Text("Track your hydration journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Chart
                chartView
                
                // Statistics Cards
                statisticsCards
                
                // Share Button
                shareButton
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Water Intake")
                .font(.headline)
                .padding(.horizontal)
            
            let data = getChartData()
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        BarMark(
                            x: .value("Day", getLabel(for: index)),
                            y: .value("Amount", value)
                        )
                        .foregroundStyle(
                            value >= (waterManager.userProfile?.dailyGoal ?? 2000)
                            ? Color.green.gradient
                            : Color.blue.gradient
                        )
                    }
                    
                    if let goal = waterManager.userProfile?.dailyGoal {
                        RuleMark(y: .value("Goal", goal))
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    }
                }
                .frame(height: 250)
                .padding()
            } else {
                // Fallback for iOS 15
                SimpleBarChart(data: data, goal: waterManager.userProfile?.dailyGoal ?? 2000)
                    .frame(height: 250)
                    .padding()
            }
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private var statisticsCards: some View {
        let stats = waterManager.getStatistics()
        
        return VStack(spacing: 15) {
            Text("Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                StatCard(
                    title: "Daily Average",
                    value: "\(Int(stats.dailyAverage)) ml",
                    icon: "drop.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Best Day",
                    value: "\(Int(stats.bestDayAmount)) ml",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Current Streak",
                    value: "\(stats.currentStreak) days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Goals Hit",
                    value: "\(stats.goalAchievedDays)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var shareButton: some View {
        Button(action: shareProgress) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Progress")
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
        .padding(.horizontal)
    }
    
    private func getChartData() -> [Double] {
        switch selectedPeriod {
        case .day:
            return getHourlyData()
        case .week:
            return waterManager.getEntriesForDays(days: 7)
        case .month:
            return waterManager.getEntriesForDays(days: 30)
        }
    }
    
    private func getHourlyData() -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayEntries = waterManager.getTodayEntries()
        
        var hourlyData: [Double] = Array(repeating: 0, count: 24)
        
        for entry in todayEntries {
            let hour = calendar.component(.hour, from: entry.timestamp)
            hourlyData[hour] += entry.amount
        }
        
        // Return only hours with data or current hour
        let currentHour = calendar.component(.hour, from: Date())
        return Array(hourlyData.prefix(currentHour + 1))
    }
    
    private func getLabel(for index: Int) -> String {
        switch selectedPeriod {
        case .day:
            return "\(index)h"
        case .week:
            let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            return index < days.count ? days[index] : ""
        case .month:
            return "\(index + 1)"
        }
    }
    
    private func shareProgress() {
        let stats = waterManager.getStatistics()
        let text = """
        🌊 My Hydro Guru Progress 🌊
        
        💧 Daily Average: \(Int(stats.dailyAverage)) ml
        ⭐ Best Day: \(Int(stats.bestDayAmount)) ml
        🔥 Current Streak: \(stats.currentStreak) days
        ✅ Goals Achieved: \(stats.goalAchievedDays) times
        
        Stay hydrated! 💙
        """
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Simple Bar Chart (iOS 15 Fallback)
struct SimpleBarChart: View {
    let data: [Double]
    let goal: Double
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.max() ?? 0, goal)
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    VStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(value >= goal ? Color.green : Color.blue)
                            .frame(height: CGFloat(value / maxValue) * (geometry.size.height - 40))
                    }
                }
            }
            
            // Goal line
            Rectangle()
                .fill(Color.red.opacity(0.5))
                .frame(height: 2)
                .offset(y: geometry.size.height - CGFloat(goal / maxValue) * (geometry.size.height - 40) - 40)
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatisticsView()
                .environmentObject(WaterManager())
        }
    }
}

