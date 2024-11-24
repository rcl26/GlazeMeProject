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
            LoginView() // Start with LoginView
        }
    }
}

