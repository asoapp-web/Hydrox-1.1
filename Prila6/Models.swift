//
//  Models.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import Foundation
import SwiftUI

// MARK: - User Profile
struct UserProfile: Codable {
    var gender: Gender
    var weight: Double // in kg
    var activityLevel: ActivityLevel
    var climate: Climate
    var dailyGoal: Double // in ml
    
    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
    }
    
    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentary"
        case light = "Light"
        case moderate = "Moderate"
        case active = "Active"
        case veryActive = "Very Active"
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.0
            case .light: return 1.1
            case .moderate: return 1.2
            case .active: return 1.3
            case .veryActive: return 1.4
            }
        }
    }
    
    enum Climate: String, Codable, CaseIterable {
        case cold = "Cold"
        case moderate = "Moderate"
        case hot = "Hot"
        
        var multiplier: Double {
            switch self {
            case .cold: return 0.9
            case .moderate: return 1.0
            case .hot: return 1.2
            }
        }
    }
    
    static func calculateDailyGoal(weight: Double, gender: Gender, activityLevel: ActivityLevel, climate: Climate) -> Double {
        // Base calculation: 35ml per kg of body weight
        let baseAmount = weight * 35
        
        // Gender adjustment
        let genderMultiplier = gender == .male ? 1.0 : 0.95
        
        // Apply multipliers
        let total = baseAmount * genderMultiplier * activityLevel.multiplier * climate.multiplier
        
        return round(total / 100) * 100 // Round to nearest 100ml
    }
}

// MARK: - Water Entry
struct WaterEntry: Identifiable, Codable {
    let id: UUID
    let amount: Double // in ml
    let timestamp: Date
    
    init(id: UUID = UUID(), amount: Double, timestamp: Date = Date()) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
    }
}

// MARK: - Daily Quote
struct DailyQuote {
    let text: String
    
    static let quotes = [
        "Drink water — and your body will thank you!",
        "One more sip towards your goal.",
        "Balance starts with a simple drop.",
        "Refresh your mind — drink some water.",
        "Your health begins with a sip.",
        "Water — the source of energy and clarity.",
        "Don't wait for thirst — act ahead!",
        "Sip by sip — to a better version of yourself.",
        "You're closer to your goal than it seems.",
        "Drink often — live easier.",
        "Stay hydrated, stay healthy!",
        "Your body is 60% water — keep it topped up!",
        "Water is the best medicine.",
        "Hydration is the key to vitality.",
        "Every drop counts!"
    ]
    
    static func dailyQuote() -> String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % quotes.count
        return quotes[index]
    }
}

// MARK: - App Settings
struct AppSettings: Codable {
    var appearanceMode: AppearanceMode
    var useMetric: Bool // true = ml, false = oz
    var notificationsEnabled: Bool
    var notificationInterval: Int // in minutes
    var notificationStartHour: Int
    var notificationEndHour: Int
    var soundEnabled: Bool
    
    enum AppearanceMode: String, Codable, CaseIterable {
        case automatic = "Automatic"
        case light = "Light"
        case dark = "Dark"
    }
    
    // Legacy support for old isDarkMode setting
    var isDarkMode: Bool {
        get { appearanceMode == .dark }
        set { appearanceMode = newValue ? .dark : .light }
    }
    
    static let `default` = AppSettings(
        appearanceMode: .automatic,
        useMetric: true,
        notificationsEnabled: true,
        notificationInterval: 60,
        notificationStartHour: 8,
        notificationEndHour: 22,
        soundEnabled: true
    )
}

// MARK: - Statistics
struct WaterStatistics {
    let dailyAverage: Double
    let weeklyAverage: Double
    let monthlyAverage: Double
    let bestDay: Date?
    let bestDayAmount: Double
    let currentStreak: Int
    let goalAchievedDays: Int
}

