//
//  WaterManager.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import Foundation
import Combine
import UserNotifications

class WaterManager: ObservableObject {
    @Published var waterEntries: [WaterEntry] = []
    @Published var userProfile: UserProfile?
    @Published var settings: AppSettings = .default
    @Published var todayTotal: Double = 0
    
    private let entriesKey = "waterEntries"
    private let profileKey = "userProfile"
    private let settingsKey = "appSettings"
    
    init() {
        loadData()
        calculateTodayTotal()
    }
    
    // MARK: - Water Entry Management
    func addWater(amount: Double) {
        let entry = WaterEntry(amount: amount)
        waterEntries.append(entry)
        calculateTodayTotal()
        saveEntries()
    }
    
    func deleteEntry(_ entry: WaterEntry) {
        waterEntries.removeAll { $0.id == entry.id }
        calculateTodayTotal()
        saveEntries()
    }
    
    func getTodayEntries() -> [WaterEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return waterEntries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: today)
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func calculateTodayTotal() {
        todayTotal = getTodayEntries().reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Profile Management
    func updateProfile(_ profile: UserProfile) {
        userProfile = profile
        saveProfile()
    }
    
    func calculateAndSetGoal(weight: Double, gender: UserProfile.Gender, activityLevel: UserProfile.ActivityLevel, climate: UserProfile.Climate) {
        let goal = UserProfile.calculateDailyGoal(weight: weight, gender: gender, activityLevel: activityLevel, climate: climate)
        
        var profile = userProfile ?? UserProfile(
            gender: gender,
            weight: weight,
            activityLevel: activityLevel,
            climate: climate,
            dailyGoal: goal
        )
        
        profile.gender = gender
        profile.weight = weight
        profile.activityLevel = activityLevel
        profile.climate = climate
        profile.dailyGoal = goal
        
        updateProfile(profile)
    }
    
    // MARK: - Settings Management
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        saveSettings()
        
        if newSettings.notificationsEnabled {
            NotificationManager.shared.scheduleNotifications(settings: newSettings)
        } else {
            NotificationManager.shared.cancelAllNotifications()
        }
    }
    
    // MARK: - Statistics
    func getStatistics() -> WaterStatistics {
        let calendar = Calendar.current
        let now = Date()
        
        // Daily average (last 7 days)
        let last7Days = getEntriesForDays(days: 7)
        let dailyAverage = last7Days.isEmpty ? 0 : last7Days.reduce(0, +) / Double(7)
        
        // Weekly average (last 4 weeks)
        let last28Days = getEntriesForDays(days: 28)
        let weeklyAverage = last28Days.isEmpty ? 0 : last28Days.reduce(0, +) / Double(4)
        
        // Monthly average (last 30 days)
        let last30Days = getEntriesForDays(days: 30)
        let monthlyAverage = last30Days.isEmpty ? 0 : last30Days.reduce(0, +) / Double(30)
        
        // Best day
        var bestDay: Date?
        var bestDayAmount: Double = 0
        
        let allDays = getAllDaysWithTotals()
        for (date, amount) in allDays {
            if amount > bestDayAmount {
                bestDayAmount = amount
                bestDay = date
            }
        }
        
        // Goal achieved days
        let goalAchievedDays = allDays.filter { $0.value >= (userProfile?.dailyGoal ?? 2000) }.count
        
        // Current streak
        let currentStreak = calculateCurrentStreak()
        
        return WaterStatistics(
            dailyAverage: dailyAverage,
            weeklyAverage: weeklyAverage,
            monthlyAverage: monthlyAverage,
            bestDay: bestDay,
            bestDayAmount: bestDayAmount,
            currentStreak: currentStreak,
            goalAchievedDays: goalAchievedDays
        )
    }
    
    func getEntriesForDays(days: Int) -> [Double] {
        let calendar = Calendar.current
        var totals: [Double] = []
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            
            let dayEntries = waterEntries.filter { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: dayStart)
            }
            
            let total = dayEntries.reduce(0) { $0 + $1.amount }
            totals.append(total)
        }
        
        return totals.reversed()
    }
    
    private func getAllDaysWithTotals() -> [Date: Double] {
        let calendar = Calendar.current
        var dayTotals: [Date: Double] = [:]
        
        for entry in waterEntries {
            let dayStart = calendar.startOfDay(for: entry.timestamp)
            dayTotals[dayStart, default: 0] += entry.amount
        }
        
        return dayTotals
    }
    
    private func calculateCurrentStreak() -> Int {
        guard let goal = userProfile?.dailyGoal else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEntries = waterEntries.filter { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: dayStart)
            }
            
            let dayTotal = dayEntries.reduce(0) { $0 + $1.amount }
            
            if dayTotal >= goal {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    func getProgress() -> Double {
        guard let goal = userProfile?.dailyGoal, goal > 0 else { return 0 }
        return min(todayTotal / goal, 1.0)
    }
    
    // MARK: - Data Persistence
    func clearAllData() {
        waterEntries = []
        todayTotal = 0
        saveEntries()
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(waterEntries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    private func loadData() {
        // Load entries
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([WaterEntry].self, from: data) {
            waterEntries = decoded
        }
        
        // Load profile
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = decoded
        }
        
        // Load settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }
    
    // Convert ml to oz
    func mlToOz(_ ml: Double) -> Double {
        return ml * 0.033814
    }
    
    // Convert oz to ml
    func ozToMl(_ oz: Double) -> Double {
        return oz / 0.033814
    }
}

