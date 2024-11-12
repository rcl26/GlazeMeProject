import SwiftUI
import Foundation

struct ContentView: View {
    @State private var commentText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    @State private var isLoading: Bool = false
    @State private var uploadedImages: [UIImage] = []
    @State private var gptResponse: String = ""
    @State private var isModalPresented: Bool = false


    
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
                            
                            // Edit Icon Overlay with Glowing Outline when GPT response is present
                            Button(action: {
                                isImagePickerPresented = true
                                gptResponse = ""  // Clear the previous response
                            })
 {
                                Image(systemName: "pencil.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: gptResponse.isEmpty ? [.clear] : [.yellow, .orange, .red]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: gptResponse.isEmpty ? 0 : 4
                                            )
                                            .opacity(gptResponse.isEmpty ? 0 : 1)
                                            .animation(gptResponse.isEmpty ? .none : .easeInOut(duration: 1.0).repeatForever(), value: gptResponse)
                                    )
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
                
                // Comment Input Field - Hide when response is present
                if gptResponse.isEmpty {
                    TextField("Add comments here (optional)", text: $commentText)
                        .padding(.all, 20)
                        .background(Color.blue.opacity(1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .frame(width: 350, height: 120)
                        .multilineTextAlignment(.leading)
                        .offset(x: 0, y: -50)
                }

                
                Spacer()
                // Glaze Me Button or Display GPT Response
                if gptResponse.isEmpty {
                    // Show "Glaze Me" button when there's no response yet
                    Button(action: {
                        isLoading = true
                        if let selectedImage = selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                            // Step 1: Analyze the image with Vision API using VisionService
                            VisionService.analyzeImage(with: imageData, apiKey: Config.googleVisionAPIKey) { description in
                                if let description = description {
                                    // Step 2: Use Vision's description to prompt GPT-4 API using GPTService
                                    GPTService.getGPTResponse(prompt: description) { response in
                                        DispatchQueue.main.async {
                                            isLoading = false
                                            if let response = response {
                                                self.gptResponse = response
                                                uploadedImages.append(selectedImage)
                                                isModalPresented = true  // Show the modal when response is ready
                                            } else {
                                                self.gptResponse = "Failed to generate response."
                                            }
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        isLoading = false
                                        self.gptResponse = "Failed to analyze the image."
                                    }
                                }
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
                } else {
                    // Show the GPT Response once available
                    if !gptResponse.isEmpty {
                        Text(gptResponse)
                            .font(.custom("Lemonada-Regular", size: 20))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(15)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)  // Ensures full height for the response
                            .padding(.top, 50)
                    }




                }

                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]), startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea()
            .sheet(isPresented: $isModalPresented) {
                VStack {
                    // Smaller Circular Image
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .padding(.top, 20)
                    }

                    // GPT Response Text
                    Text(gptResponse)
                        .font(.custom("Lemonada-Regular", size: 20))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(15)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)

                    Spacer()

                    // Close Button
                    Button(action: {
                        isModalPresented = false
                        selectedImage = nil  // Clear the selected image
                        gptResponse = ""  // Clear the GPT response
                        commentText = ""  // Clear the comment text
                    }) {
                        Text("Close")
                            .font(.custom("Lemonada-Bold", size: 20))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color.yellow)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                    .padding(.bottom, 30)

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]), startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()
            }
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
