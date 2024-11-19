import SwiftUI
import UIKit

// This struct allows the use of UIImagePickerController within SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    // This function creates and returns the UIImagePickerController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator  // Set the delegate
        picker.sourceType = .photoLibrary  // You can change this to .camera for camera access
        return picker
    }

    // This function allows the UIKit component to be updated if necessary
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    // This function creates a coordinator to handle UIImagePickerController delegate methods
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    // Coordinator class to handle the delegate methods
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        // Delegate method when an image is selected
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage  // Pass the selected image back to the parent view
            }
            picker.dismiss(animated: true)  // Dismiss the picker after selecting the image
        }

        // Delegate method to handle cancellation of image picker
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)  // Dismiss the picker if cancelled
        }
    }
}

