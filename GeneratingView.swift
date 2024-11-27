import SwiftUI


struct GeneratingView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            VStack {
                Text("Generating...")
                    .font(.custom("Lemonada-Bold", size: 28))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    .scaleEffect(2.0)
            }
        }
    }
}

