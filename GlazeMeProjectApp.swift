import SwiftUI
import Firebase // Import Firebase to configure it

@main
struct CaptionApp: App {
    // Toggle this flag to true for testing, false for production
    @State private var isTestingMode: Bool = false

    init() {
        FirebaseApp.configure() // Initialize Firebase here
    }

    var body: some Scene {
        WindowGroup {
            if isTestingMode {
                SplashView(skipToMain: true) // Skips directly to main view for testing
            } else {
                SplashView(skipToMain: false) // Shows login/signup flow
            }
        }
    }
}

