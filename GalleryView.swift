import SwiftUI

struct GalleryView: View {
    @Binding var uploadedImages: [UIImage]
    
    var body: some View {
        VStack {
            // Headline
            Text("Gallery")
                .font(.custom("Lemonada-Medium", size: 28)).foregroundColor(.white)
                .padding(.top, 0)
                .offset(y: -80)
            if !uploadedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(uploadedImages, id: \ .self) { image in
                                        VStack {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 250, height: 250)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                    
                                Button(action: {
                                    // Action for reminiscing can be added here
                                }) {
                                    Text("View")
                                        .font(.custom("Lemonada-Bold", size: 16))
                                        .frame(width: 150, height: 40)
                                        .background(Color.yellow)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding()
                    .offset(y: -10)
                }
            } else {
                Text("No images uploaded yet.")
                    .font(.custom("Lemonada-Regular", size: 20))
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]), startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
    }
}

struct GalleryView_Previews: PreviewProvider {
    @State static var sampleImages: [UIImage] = [
        UIImage(named: "example1") ?? UIImage(), // Provide a default empty image
        UIImage(named: "example2") ?? UIImage()  // Provide a default empty image
    ]

    static var previews: some View {
        GalleryView(uploadedImages: $sampleImages)
    }
}

