// PhotoPickerRepresentable.swift
// UIViewControllerRepresentable wrapping PHPickerViewController.
// Returns [String] — PHAsset local identifiers — not UIImages.
// The identifier is what we persist; the image is loaded on demand via PHImageManager.
import SwiftUI
import PhotosUI

// MARK: - PhotoPickerRepresentable

struct PhotoPickerRepresentable: UIViewControllerRepresentable {

    /// Receives the selected PHAsset local identifiers.
    let onPick: ([String]) -> Void

    var selectionLimit: Int = 10

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = selectionLimit
        config.filter = .images
        // .ordered preserves selection order and populates result.assetIdentifier
        config.selection = .ordered

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {

        let onPick: ([String]) -> Void

        init(onPick: @escaping ([String]) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            let ids = results.compactMap(\.assetIdentifier)
            onPick(ids)
        }
    }
}
