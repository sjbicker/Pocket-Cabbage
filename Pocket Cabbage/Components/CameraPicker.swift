//
//  CameraPicker.swift
//  Pocket Cabbage
//
//  Image capture for the pantry/ad/receipt scanners. On iOS it uses the camera
//  (falling back to the photo library in the simulator); the captured image is
//  re-encoded to JPEG and handed back as base64 for the backend vision calls.
//  UIKit-only code is guarded so the app still builds on macOS/visionOS.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// Re-encodes an image to JPEG and returns base64 (backend expects image/jpeg).
func encodeJPEGBase64(_ image: UIImage, quality: CGFloat = 0.7) -> String? {
    image.jpegData(compressionQuality: quality)?.base64EncodedString()
}
#endif

/// A tappable control that captures a photo and returns `(base64, mediaType)`.
struct CaptureControl<Label: View>: View {
    var onCapture: (_ base64: String, _ mediaType: String) -> Void
    @ViewBuilder var label: () -> Label

    @State private var showCapture = false

    var body: some View {
        Button { showCapture = true } label: { label() }
            .buttonStyle(.plain)
        #if os(iOS)
            .sheet(isPresented: $showCapture) {
                CameraController { image in
                    if let base64 = encodeJPEGBase64(image) {
                        onCapture(base64, "image/jpeg")
                    }
                }
                .ignoresSafeArea()
            }
        #endif
    }
}

#if os(iOS)
/// Wraps UIImagePickerController; uses the camera when available, else library.
struct CameraController: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraController
        init(_ parent: CameraController) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif
