// PhotoPickerRepresentable.swift
// UIViewControllerRepresentable wrapping PHPickerViewController.
// Loads UIImage directly from NSItemProvider and returns JPEG Data.
// No Photos library permission required.
import SwiftUI
import PhotosUI

// MARK: - PhotoPickerRepresentable

struct PhotoPickerRepresentable: UIViewControllerRepresentable {

    /// Receives JPEG-compressed image data for the selected photos.
    let onPick: ([Data]) -> Void

    var selectionLimit: Int = 10

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()   // no photoLibrary: — avoids permission prompt
        config.selectionLimit = selectionLimit
        config.filter = .images
        config.selection = .ordered

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {

        let onPick: ([Data]) -> Void

        init(onPick: @escaping ([Data]) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { onPick([]); return }

            Task {
                var dataItems: [Data] = []
                for result in results {
                    guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                    let image = await withCheckedContinuation { (cont: CheckedContinuation<UIImage?, Never>) in
                        result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                            cont.resume(returning: object as? UIImage)
                        }
                    }
                    guard let image,
                          let data = image.scaledForStorage().jpegData(compressionQuality: 0.8)
                    else { continue }
                    dataItems.append(data)
                }
                await MainActor.run { self.onPick(dataItems) }
            }
        }
    }
}

// MARK: - UIImage resize helper

private extension UIImage {
    /// Scales down to a maximum dimension of 1200 px while preserving aspect ratio.
    /// Returns self unchanged when already within bounds.
    func scaledForStorage(maxDimension: CGFloat = 1200) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
