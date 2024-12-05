import SwiftUI

struct SplashView: View {
    @State private var animate = false
    @State private var navigateToNextView = false
    var skipToMain: Bool // Controls navigation to the main or login view

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Redesigned Logo
                ZStack {
                    // Abstract layered shapes for the logo
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.yellow.opacity(0.9))
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(animate ? 15 : -15))
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(), value: animate)

                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(animate ? -15 : 15))
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(), value: animate)

                    // Bold, modern text inside the logo with line break
                    Text("Cap\nCall")
                        .font(.custom("Lemonada-Bold", size: 42)) // Adjust size to fit inside the logo
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center) // Center align text inside the logo
                }
                .onAppear {
                    animate = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + (skipToMain ? 3 : 3)) {
                        navigateToNextView = true
                    }
                }

                // Subtitle
                Text("AI-generated captions")
                    .font(.custom("Lemonada-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .padding()
        }
        .fullScreenCover(isPresented: $navigateToNextView) {
            if skipToMain {
                ContentView() // Navigate directly to Content View
            } else {
                LoginView() // Navigate to Login View
            }
        }
    }
}

