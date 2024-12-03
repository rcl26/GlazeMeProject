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
    @State private var isPaywallPresented: Bool = false
    @State private var captionSafe: String = "" // Holds the "Safe" response
    @State private var captionMedium: String = "" // Holds the "Medium" response
    @State private var captionBold: String = "" // Holds the "Bold" response
    @State private var animateCircle: Bool = false
    @State private var isGeneratingViewPresented: Bool = false
    @State private var safeSearchErrorMessage: String = ""
    @State private var isSafeSearchErrorPresented: Bool = false
    @State private var isProfilePresented: Bool = false
    






    
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
                            .scaleEffect(animateCircle ? 1.05 : 1.0) // Pulsing animation
                            .animation(animateCircle ? Animation.easeInOut(duration: 1.5).repeatForever() : .default, value: animateCircle)
                        
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
                .sheet(isPresented: $isImagePickerPresented, onDismiss: {
                    // Stop the pulse if an image is uploaded
                    animateCircle = selectedImage == nil
                }) {
                    ImagePicker(selectedImage: $selectedImage)
                }
                .onAppear {
                    // Start the pulse only if no image is uploaded
                    animateCircle = selectedImage == nil
                }
                .onChange(of: selectedImage) {
                    animateCircle = selectedImage == nil
                }




                // Comment Input Field
                if gptResponse.isEmpty {
                    TextField("Make a caption about...", text: $commentText)
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
                        // Caption this Button
                        Button(action: {
                            // Check subscription status
                            let isSubscribed = UserDefaults.standard.bool(forKey: "isSubscribed")
                            print("Subscription Status:", isSubscribed)

                            if !isSubscribed {
                                // Trigger paywall for non-subscribed users
                                isPaywallPresented = true
                                return
                            }

                            // Proceed to caption generation for subscribed users
                            isLoading = true
                            if let selectedImage = selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                                VisionService.analyzeImage(with: imageData, apiKey: Config.googleVisionAPIKey) { structuredData in
                                    if let structuredData = structuredData {
                                        print("Debug – Structured Data in Completion Block: \(structuredData)")

                                        // Check for errors or process the response
                                        if let error = structuredData["error"] as? String {
                                            DispatchQueue.main.async {
                                                isLoading = false
                                                safeSearchErrorMessage = "The image contains inappropriate content and cannot be processed."
                                                isSafeSearchErrorPresented = true
                                            }
                                            print("Error detected in structured data: \(error)") // Debug log
                                            return
                                        }

                                        // Pass valid data to GPT Service
                                        GPTService.getGPTResponse(
                                            subject: "subject",
                                            context: structuredData,
                                            isGroupPhoto: false,
                                            commentText: commentText
                                        ) { response in
                                            DispatchQueue.main.async {
                                                self.isLoading = false
                                                if let captions = response {
                                                    self.captionSafe = captions["safe"] ?? "Safe caption missing"
                                                    self.captionMedium = captions["medium"] ?? "Medium caption missing"
                                                    self.captionBold = captions["bold"] ?? "Bold caption missing"
                                                    self.isModalPresented = true
                                                } else {
                                                    self.captionSafe = "Safe caption missing"
                                                    self.captionMedium = "Medium caption missing"
                                                    self.captionBold = "Bold caption missing"
                                                    self.gptResponse = "Failed to generate a response."
                                                    self.isModalPresented = true
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
                            Text("Caption this")
                                .font(.custom("Lemonada-Bold", size: 24))
                                .frame(width: 250, height: 75)
                                .background(Color.yellow)
                                .foregroundColor(.white)
                                .cornerRadius(100)
                        }
                        .offset(x: 0, y: -90)
                        .opacity(isLoading ? 0 : 1) // Hide button when loading
                        .sheet(isPresented: $isPaywallPresented) {
                            PaywallView(onSubscribe: {
                                // Update subscription status in UserDefaults
                                UserDefaults.standard.set(true, forKey: "isSubscribed")
                                isPaywallPresented = false // Dismiss paywall
                            })
                        }


                        // Loading Animation
                        if isLoading {
                            VStack(spacing: 10) {
                                Text("Generating")
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
            
            
            .sheet(isPresented: $isSafeSearchErrorPresented) {
                VStack(spacing: 20) {
                    Text("Content Blocked")
                        .font(.custom("Lemonada-Bold", size: 24))
                        .foregroundColor(.red)
                        .padding()

                    Text(safeSearchErrorMessage)
                        .font(.custom("Lemonada-Regular", size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()

                    Button(action: {
                        isSafeSearchErrorPresented = false
                    }) {
                        Text("OK")
                            .font(.custom("Lemonada-Bold", size: 16))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black]), startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()
            }

            
            // Modal View
            .sheet(isPresented: $isModalPresented) {
                if isLoading {
                    // Show the loading transition view while generating captions
                    GeneratingView()
                } else {
                    GeometryReader { geometry in
                        VStack(spacing: 20) {
                            // Display the uploaded image
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .padding(.top, 20)
                            }

                            // Caption Sections
                            VStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Safe Caption Section
                                    Text("Safe")
                                        .font(.custom("Lemonada-Bold", size: 14))
                                        .foregroundColor(Color.yellow.opacity(0.6))
                                        .padding(.leading, 10)

                                    Text(captionSafe)
                                        .font(.custom("Lemonada-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(10)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    // Neutral Caption Section
                                    Text("Neutral")
                                        .font(.custom("Lemonada-Bold", size: 14))
                                        .foregroundColor(Color.yellow.opacity(0.6))
                                        .padding(.leading, 10)

                                    Text(captionMedium)
                                        .font(.custom("Lemonada-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(10)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    // Bold Caption Section
                                    Text("Bold")
                                        .font(.custom("Lemonada-Bold", size: 14))
                                        .foregroundColor(Color.yellow.opacity(0.6))
                                        .padding(.leading, 10)

                                    Text(captionBold)
                                        .font(.custom("Lemonada-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(10)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.horizontal, 20)

                            Spacer()

                            // Buttons
                            HStack(spacing: 20) {
                                // Close Button
                                Button(action: {
                                    // Close Modal Functionality
                                    isModalPresented = false
                                    selectedImage = nil
                                    gptResponse = ""
                                    commentText = ""
                                    captionSafe = ""
                                    captionMedium = ""
                                    captionBold = ""
                                }) {
                                    Text("Close")
                                        .font(.custom("Lemonada-Bold", size: 15))
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 15)
                                        .background(Color.red.opacity(0.5)) // Softer yellow
                                        .foregroundColor(.white)
                                        .cornerRadius(25)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 2)
                                        )
                                }

                                // Try Again Button
                                Button(action: {
                                    isLoading = true // Show the loading screen
                                    if let selectedImage = selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                                        VisionService.analyzeImage(with: imageData, apiKey: Config.googleVisionAPIKey) { structuredData in
                                            if let structuredData = structuredData {
                                                GPTService.getGPTResponse(
                                                    subject: "subject",
                                                    context: structuredData,
                                                    isGroupPhoto: false,
                                                    commentText: commentText
                                                ) { newCaptions in
                                                    DispatchQueue.main.async {
                                                        isLoading = false // Hide the loading screen
                                                        if let newCaptions = newCaptions {
                                                            // Update captions with new responses
                                                            captionSafe = newCaptions["safe"] ?? "Safe caption missing"
                                                            captionMedium = newCaptions["medium"] ?? "Neutral caption missing"
                                                            captionBold = newCaptions["bold"] ?? "Bold caption missing"
                                                        }
                                                    }
                                                }
                                            } else {
                                                DispatchQueue.main.async {
                                                    isLoading = false // Hide the loading screen
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    Text("Try Again")
                                        .font(.custom("Lemonada-Bold", size: 15))
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 15)
                                        .background(Color.yellow.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(25)
                                }
                            }
                            .padding(.bottom, 50) // Adjust bottom padding for better spacing
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]), startPoint: .top, endPoint: .bottom))
                        .ignoresSafeArea()
                    }
                }
            }






            .tabItem {
                Label("Upload", systemImage: "camera.fill")
            }

            // Replace Gallery View with Profile View
            ProfileView(isProfilePresented: $isProfilePresented)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }


        }
    }
}
