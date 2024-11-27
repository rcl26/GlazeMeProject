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

                // Logo: Two "C"s for "Cap Call"
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.9)) // Yellow circle for logo
                        .frame(width: 200, height: 200)
                        .scaleEffect(animate ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(), value: animate)

                    Text("C C")
                        .font(.custom("Lemonada-Bold", size: 64))
                        .foregroundColor(.white)
                }
                .onAppear {
                    animate = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + (skipToMain ? 3 : 3)) {
                        navigateToNextView = true
                    }
                }

                // App Name
                Text("Cap Call")
                    .font(.custom("Lemonada-Bold", size: 32))
                    .foregroundColor(.white)

                // Subtitle
                Text("Capture the moment, call the caption.")
                    .font(.custom("Lemonada-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.8))
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

