//
//  SettingsView.swift
//  Hydro Guru
//
//  Created on 11/2/2025.
//

import SwiftUI
import AVFoundation
import Photos

struct SettingsView: View {
    @EnvironmentObject var waterManager: WaterManager
    @StateObject private var hydroPhotoManager = PrilaProfilePhotoManager.shared
    @State private var appearanceMode: AppSettings.AppearanceMode = .automatic
    @State private var useMetric: Bool = true
    @State private var showingClearDataAlert = false
    @State private var hydroShowImagePicker = false
    @State private var hydroImagePickerSource: PrilaImagePickerSource = .photoLibrary
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            // Profile Photo Section
            Section(header: Text("Profile Photo")) {
                if let img = hydroPhotoManager.hydroProfilePhoto {
                    HStack {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        Spacer()
                        Button("Remove") {
                            hydroPhotoManager.hydroDeletePhoto()
                        }
                        .foregroundColor(.red)
                    }
                }
                Button("Choose from Library") {
                    requestPhotoLibraryAccess { granted in
                        if granted {
                            hydroImagePickerSource = .photoLibrary
                            hydroShowImagePicker = true
                        }
                    }
                }
                Button("Take Photo") {
                    requestCameraAccess { granted in
                        if granted {
                            hydroImagePickerSource = .camera
                            hydroShowImagePicker = true
                        }
                    }
                }
            }

            // Appearance Section
            Section(header: Text("Appearance")) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text("Theme")
                    
                    Spacer()
                    
                    Picker("", selection: $appearanceMode) {
                        ForEach(AppSettings.AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: appearanceMode) { newValue in
                        var settings = waterManager.settings
                        settings.appearanceMode = newValue
                        waterManager.updateSettings(settings)
                    }
                }
            }
            
            // Units Section
            Section(header: Text("Units")) {
                HStack {
                    Image(systemName: "ruler.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text("Measurement Units")
                    
                    Spacer()
                    
                    Picker("", selection: $useMetric) {
                        Text("Milliliters").tag(true)
                        Text("Ounces").tag(false)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: useMetric) { newValue in
                        var settings = waterManager.settings
                        settings.useMetric = newValue
                        waterManager.updateSettings(settings)
                    }
                }
            }
            
            // Goal Section
            Section(header: Text("Water Goal")) {
                if let profile = waterManager.userProfile {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text("Daily Goal")
                                .font(.body)
                            Text("\(Int(profile.dailyGoal)) ml")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        
                        Text("No goal set")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Statistics Section
            Section(header: Text("Your Statistics")) {
                let stats = waterManager.getStatistics()
                
                StatRow(
                    icon: "drop.fill",
                    title: "Daily Average",
                    value: "\(Int(stats.dailyAverage)) ml",
                    color: .blue
                )
                
                StatRow(
                    icon: "flame.fill",
                    title: "Current Streak",
                    value: "\(stats.currentStreak) days",
                    color: .orange
                )
                
                StatRow(
                    icon: "checkmark.circle.fill",
                    title: "Goals Achieved",
                    value: "\(stats.goalAchievedDays) times",
                    color: .green
                )
            }
            
            // Data Management Section
            Section(header: Text("Data Management")) {
                Button(action: {
                    showingClearDataAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .frame(width: 30)
                        
                        Text("Clear All Data")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // About Section
            Section(header: Text("About")) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text("Version")
                    
                    Spacer()
                    
                    Text("1.1")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .frame(width: 30)
                    
                    Text("Made with Love")
                    
                    Spacer()
                    
                    Text("Hydro Guru")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear(perform: loadSettings)
        .alert(isPresented: $showingClearDataAlert) {
            Alert(
                title: Text("Clear All Data?"),
                message: Text("This will delete all your water entries. This action cannot be undone."),
                primaryButton: .destructive(Text("Clear")) {
                    clearAllData()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $hydroShowImagePicker) {
            if UIImagePickerController.isSourceTypeAvailable(hydroImagePickerSource.sourceType) {
                PrilaImagePicker(
                    hydroSourceType: hydroImagePickerSource.sourceType,
                    hydroOnImagePicked: { image in
                        if let image = image {
                            hydroPhotoManager.hydroSavePhoto(image)
                        }
                        hydroShowImagePicker = false
                    },
                    hydroOnCancel: { hydroShowImagePicker = false }
                )
            }
        }
    }

    private func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    private func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }

    private func loadSettings() {
        appearanceMode = waterManager.settings.appearanceMode
        useMetric = waterManager.settings.useMetric
    }
    
    private func clearAllData() {
        waterManager.clearAllData()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(WaterManager())
        }
    }
}

