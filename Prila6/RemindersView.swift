//
//  RemindersView.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import SwiftUI

struct RemindersView: View {
    @EnvironmentObject var waterManager: WaterManager
    @State private var notificationsEnabled: Bool = true
    @State private var intervalMinutes: Double = 60
    @State private var startHour: Double = 8
    @State private var endHour: Double = 22
    @State private var soundEnabled: Bool = true
    @State private var showingPermissionAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                headerSection
                settingsSection
                saveButton
            }
            .padding(.vertical)
        }
        .navigationTitle("Reminders")
        .onAppear(perform: loadSettings)
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text("Notifications Disabled"),
                message: Text("Please enable notifications in Settings to receive water reminders."),
                primaryButton: .default(Text("Open Settings"), action: openSettings),
                secondaryButton: .cancel()
            )
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Water Reminders")
                .font(.title2)
                .bold()
            
            Text("Stay on track with helpful notifications")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var settingsSection: some View {
        VStack(spacing: 20) {
            enableToggle
            
            if notificationsEnabled {
                intervalSlider
                activeHoursSection
                soundToggle
                exampleMessages
            }
        }
        .padding(.horizontal)
    }
    
    private var enableToggle: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Enable Reminders")
                    .font(.headline)
                Text("Receive regular water reminders")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $notificationsEnabled)
                .labelsHidden()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var intervalSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reminder Interval")
                    .font(.headline)
                Spacer()
                Text("\(Int(intervalMinutes)) min")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Slider(value: $intervalMinutes, in: 15...180, step: 15)
                .accentColor(.blue)
            
            HStack {
                Text("15 min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("3 hours")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var activeHoursSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Hours")
                .font(.headline)
            
            Text("Start Time: \(formatHour(Int(startHour)))")
                .font(.subheadline)
            Slider(value: $startHour, in: 0...23, step: 1)
                .accentColor(.blue)
            
            Text("End Time: \(formatHour(Int(endHour)))")
                .font(.subheadline)
            Slider(value: $endHour, in: 0...23, step: 1)
                .accentColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var soundToggle: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Notification Sound")
                    .font(.headline)
                Text("Play sound with reminders")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $soundEnabled)
                .labelsHidden()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var exampleMessages: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example Reminders")
                .font(.headline)
            
            ForEach(0..<3) { index in
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.blue)
                    Text(NotificationManager.shared.motivationalMessages[index])
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var saveButton: some View {
        Button(action: saveSettings) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Reminder Settings")
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
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"
        
        var components = DateComponents()
        components.hour = hour
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
    
    private func loadSettings() {
        let settings = waterManager.settings
        notificationsEnabled = settings.notificationsEnabled
        intervalMinutes = Double(settings.notificationInterval)
        startHour = Double(settings.notificationStartHour)
        endHour = Double(settings.notificationEndHour)
        soundEnabled = settings.soundEnabled
    }
    
    private func saveSettings() {
        var newSettings = waterManager.settings
        newSettings.notificationsEnabled = notificationsEnabled
        newSettings.notificationInterval = Int(intervalMinutes)
        newSettings.notificationStartHour = Int(startHour)
        newSettings.notificationEndHour = Int(endHour)
        newSettings.soundEnabled = soundEnabled
        
        if notificationsEnabled {
            NotificationManager.shared.requestAuthorization { granted in
                if granted {
                    waterManager.updateSettings(newSettings)
                    
                    // Show success feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } else {
                    showingPermissionAlert = true
                    notificationsEnabled = false
                }
            }
        } else {
            waterManager.updateSettings(newSettings)
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct RemindersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RemindersView()
                .environmentObject(WaterManager())
        }
    }
}

