import SwiftUI

struct GalleryView: View {
    @Binding var uploadedImages: [UIImage]
    
    var body: some View {
        VStack {
            // Headline
            Text("Gallery")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .padding(.top, 40)
            if !uploadedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(uploadedImages, id: \ .self) { image in
                            VStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 250, height: 250)
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    
                                Button(action: {
                                    // Action for reminiscing can be added here
                                }) {
                                    Text("View Glazing")
                                        .font(.system(size: 16, weight: .bold))
                                        .frame(width: 150, height: 40)
                                        .background(Color.yellow)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("No images uploaded yet.")
                    .font(.system(size: 20, weight: .regular, design: .serif))
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
    @State static var sampleImages: [UIImage] = [UIImage(named: "example1")!, UIImage(named: "example2")!]
    
    static var previews: some View {
        GalleryView(uploadedImages: $sampleImages)
    }
}
