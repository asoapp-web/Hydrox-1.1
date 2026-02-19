//
//  PrilaProfilePhotoManager.swift
//  Prila6
//
//  Hydro Guru – profile photo storage.
//

import Foundation
import UIKit
import Combine

final class PrilaProfilePhotoManager: ObservableObject {
    static let shared = PrilaProfilePhotoManager()

    @Published var hydroProfilePhoto: UIImage?

    private let hydroPhotoKey = "hydro_profile_photo_v1"

    private init() {
        hydroLoadPhoto()
    }

    func hydroSavePhoto(_ image: UIImage) {
        guard let hydroImageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        UserDefaults.standard.set(hydroImageData, forKey: hydroPhotoKey)
        hydroProfilePhoto = image
    }

    func hydroLoadPhoto() {
        guard let hydroImageData = UserDefaults.standard.data(forKey: hydroPhotoKey),
              let hydroImage = UIImage(data: hydroImageData) else {
            hydroProfilePhoto = nil
            return
        }
        hydroProfilePhoto = hydroImage
    }

    func hydroDeletePhoto() {
        UserDefaults.standard.removeObject(forKey: hydroPhotoKey)
        hydroProfilePhoto = nil
    }
}
