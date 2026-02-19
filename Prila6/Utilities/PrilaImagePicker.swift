//
//  PrilaImagePicker.swift
//  Prila6
//
//  Hydro Guru – camera and photo library picker.
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

struct PrilaImagePicker: UIViewControllerRepresentable {
    let hydroSourceType: UIImagePickerController.SourceType
    let hydroOnImagePicked: (UIImage?) -> Void
    let hydroOnCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = hydroSourceType
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> PrilaImagePickerCoordinator {
        PrilaImagePickerCoordinator(hydroOnImagePicked: hydroOnImagePicked, hydroOnCancel: hydroOnCancel)
    }

    class PrilaImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let hydroOnImagePicked: (UIImage?) -> Void
        let hydroOnCancel: () -> Void

        init(hydroOnImagePicked: @escaping (UIImage?) -> Void, hydroOnCancel: @escaping () -> Void) {
            self.hydroOnImagePicked = hydroOnImagePicked
            self.hydroOnCancel = hydroOnCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.editedImage] as? UIImage {
                hydroOnImagePicked(img)
            } else if let img = info[.originalImage] as? UIImage {
                hydroOnImagePicked(img)
            } else {
                hydroOnImagePicked(nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            hydroOnCancel()
        }
    }
}

enum PrilaImagePickerSource {
    case camera
    case photoLibrary

    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .photoLibrary: return .photoLibrary
        }
    }
}
