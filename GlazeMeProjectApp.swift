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
            ContentView() // Start with LoginView
        }
    }
}

