import SwiftUI

struct ContentView: View {
    @State private var commentText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    @State private var isLoading: Bool = false
    @State private var uploadedImages: [UIImage] = []
    
    var body: some View {
        TabView {
            VStack(spacing: 40) {
                Spacer().frame(height: 30)
                // Title Text
                Text("Upload a picture")
                    .font(.custom("Lemonada-Medium", size: 28))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .offset(y: 30)
                
                // Circular Image Upload Area
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 300, height: 300)
                        
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 300)
                                .clipShape(Circle())
                            
                            // Edit Icon Overlay
                            Button(action: {
                                isImagePickerPresented = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .offset(x: 90, y: -90)
                        } else {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                        }
                    }
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(image: $selectedImage)
                }
                
                // Comment Input Field
                TextField("How do I look in this?", text: $commentText)
                    .padding(.all, 20)
                    .background(Color.blue.opacity(1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .frame(width: 350, height: 120)
                    .multilineTextAlignment(.leading)
                    .offset(x: 0, y: -50)
                Spacer()
                // Glaze Me Button
                Button(action: {
                    isLoading = true
                    // Simulate processing delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                        if let selectedImage = selectedImage {
                            uploadedImages.append(selectedImage)
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                            .scaleEffect(2.0)
                    } else {
                        Text("Glaze me")
                            .font(.custom("Lemonada-Bold", size: 24))
                            .frame(width: 200, height: 75)
                            .background(Color.yellow)
                            .foregroundColor(.white)
                            .cornerRadius(100)
                    }
                }
                .disabled(isLoading)
                .offset(x: 0, y: -90)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]), startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea()
            .tabItem {
                Label("Upload", systemImage: "camera.fill")
            }
            
            GalleryView(uploadedImages: $uploadedImages)
                .tabItem {
                    Label("Gallery", systemImage: "photo.fill.on.rectangle.fill")
                }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
