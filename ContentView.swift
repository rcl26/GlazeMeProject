import SwiftUI
import Foundation

// Define UploadedItem struct
struct UploadedItem {
    var image: UIImage
    var response: String
}

struct ContentView: View {
    @State private var commentText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    @State private var isLoading: Bool = false
    @State private var uploadedItems: [UploadedItem] = []
    @State private var gptResponse: String = ""
    @State private var isModalPresented: Bool = false
    @State private var imageDetails: String = "" // Holds Vision API data
    



    var body: some View {
        TabView {
            // Upload View
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
                        } else {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                        }
                    }
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(selectedImage: $selectedImage)
                }

                // Comment Input Field
                if gptResponse.isEmpty {
                    TextField("Hey GlazeAi, how do I look in this?", text: $commentText)
                        .padding(.leading, 25)
                        .padding(.vertical, 20)
                        .background(Color.blue.opacity(2.0))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .frame(width: 350, height: 120)
                        .multilineTextAlignment(.leading)
                        .textFieldStyle(PlainTextFieldStyle())
                        .tint(.white) // Changes the cursor color to white
                        .offset(y: -50) // Move the text box up
                        .onChange(of: commentText) { oldValue, newValue in
                            if newValue.count > 50 {
                                commentText = String(newValue.prefix(50))
                            }
                        }

                }

                Spacer()

                // Glaze Me Button or Loading Animation
                if let _ = selectedImage, gptResponse.isEmpty {
                    ZStack {
                        // Glaze Me Button
                        Button(action: {
                            isLoading = true
                            if let selectedImage = selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                                VisionService.analyzeImage(with: imageData, apiKey: Config.googleVisionAPIKey) { structuredData in
                                    if let structuredData = structuredData {
                                        print("Debug – Structured Data in Completion Block: \(structuredData)")

                                        // Check Safe Search for inappropriate content
                                        if let error = structuredData["error"] as? String {
                                            DispatchQueue.main.async {
                                                isLoading = false
                                                gptResponse = error // Use the error message from structured data
                                                isModalPresented = true
                                            }
                                            print("Error detected in structured data: \(error)") // Debug log
                                            return // Stop further processing
                                        }



                                        // Check for no human in the image
                                        if structuredData["noHuman"] as? Bool == true {
                                            DispatchQueue.main.async {
                                                isLoading = false
                                                gptResponse = "Hmm, I don't see anyone in this picture. Try uploading a photo with people!"
                                                isModalPresented = true
                                            }
                                            return
                                        }

                                        // Check if there's a clear main subject
                                        let faceCount = (structuredData["facialExpressions"] as? [String: Any])?["count"] as? Int ?? 0
                                        let mainSubject = (structuredData["facialExpressions"] as? [String: Any])?["mainSubject"] as? [String: Any]

                                        let subject: String
                                        if faceCount > 1 && mainSubject == nil {
                                            subject = "group"
                                        } else {
                                            subject = "person"
                                        }

                                        let isGroupPhotoValue = structuredData["isGroupPhoto"] as? Bool ?? false
                                        print("Debug – Extracted isGroupPhotoValue in ContentView: \(isGroupPhotoValue)")

                                        // Pass valid data to GPT Service
                                        GPTService.getGPTResponse(
                                            subject: subject,
                                            context: structuredData,
                                            isGroupPhoto: isGroupPhotoValue,
                                            commentText: commentText
                                        ) { response in
                                            DispatchQueue.main.async {
                                                isLoading = false
                                                if let response = response {
                                                    self.gptResponse = response
                                                    uploadedItems.append(UploadedItem(image: selectedImage, response: response))
                                                    isModalPresented = true
                                                } else {
                                                    self.gptResponse = "Failed to generate a response."
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
                            Text("Glaze me")
                                .font(.custom("Lemonada-Bold", size: 24))
                                .frame(width: 200, height: 75)
                                .background(Color.yellow)
                                .foregroundColor(.white)
                                .cornerRadius(100)
                        }
                        .offset(x: 0, y: -90)
                        .opacity(isLoading ? 0 : 1) // Hide button when loading

                        // Loading Animation
                        if isLoading {
                            VStack(spacing: 10) {
                                Text("Preparing to glaze")
                                    .font(.custom("Lemonada-Bold", size: 20))
                                    .foregroundColor(Color.yellow)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                                    .scaleEffect(2.0)
                            }
                            .padding(.top, -120)
                        }
                    }
                }


                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]), startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea()
            .sheet(isPresented: $isModalPresented) {
                VStack {
                    // Display the uploaded image
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .padding(.top, 20)
                    }

                    // Display the GPT response
                    Text(gptResponse)
                        .font(.custom("Lemonada-Regular", size: 17))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(15)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)

                    // Gold Close Button
                    Button(action: {
                        // Reset the app state
                        isModalPresented = false
                        selectedImage = nil
                        gptResponse = ""
                        commentText = ""
                    }) {
                        Text("Close")
                            .font(.custom("Lemonada-Bold", size: 20))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color.yellow)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.yellow, lineWidth: 2)
                            )
                    }
                    .padding(.top, 30)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]), startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()
            }


            .tabItem {
                Label("Upload", systemImage: "camera.fill")
            }

            // Gallery View
            GalleryView(uploadedItems: $uploadedItems)
                .tabItem {
                    Label("Gallery", systemImage: "photo.fill.on.rectangle.fill")
                }
        }
    }
}
