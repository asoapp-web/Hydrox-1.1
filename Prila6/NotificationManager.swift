//
//  NotificationManager.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    let motivationalMessages = [
        "Time for a sip of freshness!",
        "You're on your way to perfect balance!",
        "Your body thanks you for water!",
        "Stay hydrated, stay healthy!",
        "Time to drink some water!",
        "Don't forget to hydrate!",
        "Your daily dose of wellness awaits!",
        "Keep the flow going!",
        "Refresh yourself with water!",
        "Water break time!"
    ]
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleNotifications(settings: AppSettings) {
        cancelAllNotifications()
        
        guard settings.notificationsEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        
        // Calculate how many notifications per day
        let startHour = settings.notificationStartHour
        let endHour = settings.notificationEndHour
        let intervalMinutes = settings.notificationInterval
        
        var currentMinutes = startHour * 60
        let endMinutes = endHour * 60
        
        var notificationId = 0
        
        while currentMinutes < endMinutes {
            let hour = currentMinutes / 60
            let minute = currentMinutes % 60
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let content = UNMutableNotificationContent()
            content.title = "Hydro Guru"
            content.body = motivationalMessages.randomElement() ?? "Time to drink water!"
            content.sound = settings.soundEnabled ? .default : nil
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "waterReminder_\(notificationId)", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
            
            currentMinutes += intervalMinutes
            notificationId += 1
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

