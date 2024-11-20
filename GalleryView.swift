import SwiftUI

struct GalleryView: View {
    @Binding var uploadedItems: [UploadedItem]
    @State private var showProfileView: Bool = false // Controls profile sheet
    @State private var navigationPath = NavigationPath() // Resets navigation stack

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                    Text("Gallery")
                        .font(.custom("Lemonada-Medium", size: 28))
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    if !uploadedItems.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 40) { // Ensure alignment at the top
                                ForEach(uploadedItems, id: \.image) { item in
                                    VStack(spacing: 10) {
                                        Image(uiImage: item.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 150)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                        Text(item.response)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 150)
                                    }
                                }
                            }
                            .padding()
                        }
                    } else {
                        Text("No images uploaded yet.")
                            .font(.custom("Lemonada-Regular", size: 20))
                            .foregroundColor(.white)
                            .padding()
                    }
                }

                // Profile Icon
                HStack {
                    Spacer()
                    Button(action: {
                        showProfileView = true // Open profile as a sheet
                    }) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                    .padding(.trailing, 30)
                    .padding(.top, 30)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
            .onAppear {
                // Reset navigation when entering the Gallery
                navigationPath = NavigationPath()
            }
        }
        // Sheet for Profile View
        .sheet(isPresented: $showProfileView) {
            ProfileView() // Profile View is now independent
        }
    }
}

