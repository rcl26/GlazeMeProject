import SwiftUI
import FirebaseCore

@main
struct GlazeMeProjectApp: App {
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            // Start with the LoginView
            LoginView()
        }
    }
}

