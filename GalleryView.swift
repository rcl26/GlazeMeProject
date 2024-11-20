import SwiftUI

struct GalleryView: View {
    @Binding var uploadedItems: [UploadedItem]

    var body: some View {
        NavigationView {
            ZStack {
                // Main Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Main Gallery Content
                VStack {
                    // Title
                    Text("Gallery")
                        .font(.custom("Lemonada-Medium", size: 28))
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    // Display Items or Placeholder
                    if !uploadedItems.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 40) { // Align items to their tops
                                ForEach(uploadedItems, id: \.image) { item in
                                    VStack(spacing: 10) { // Ensure consistent spacing between elements
                                        Image(uiImage: item.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 150) // Ensure consistent size
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                        Text(item.response)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 150) // Match width of the image
                                    }
                                }
                            }
                            .padding()
                        }

                    } else {
                        Text("No items uploaded yet.")
                            .font(.custom("Lemonada-Regular", size: 20))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
            .navigationBarHidden(true) // Hide default navigation bar
        }
    }
}

