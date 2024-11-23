import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

struct LoginView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Title Text
            Text("Glaze Me")
                .font(.custom("Lemonada-Medium", size: 28))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Description
            Text("Because Everyone Deserves Compliments")
                .font(.custom("Lemonada-Regular", size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Google Sign-In Button
            Button(action: {
                signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "globe") // Placeholder for Google logo
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                    Text("Sign in with Google")
                        .font(.custom("Lemonada-Bold", size: 20))
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .background(Color.yellow)
                .foregroundColor(.white)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.yellow, lineWidth: 2)
                )
            }
            .padding(.top, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]), startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
    }
}

// Google Sign-In Logic
func signInWithGoogle() {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
        print("Missing Firebase client ID")
        return
    }

    let config = GIDConfiguration(clientID: clientID)

    // Get the current root view controller
    guard let rootViewController = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
        .first?.rootViewController else {
        print("Unable to access root view controller")
        return
    }

    // Updated sign-in method
    GIDSignIn.sharedInstance.signIn(
        withPresenting: rootViewController
    ) { result, error in
        if let error = error {
            print("Error during Google Sign-In: \(error.localizedDescription)")
            return
        }

        guard let user = result?.user,
              let idToken = user.idToken?.tokenString else {
            print("Google Sign-In failed with no token")
            return
        }

        let accessToken = user.accessToken.tokenString

        // Create a Firebase credential
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        // Sign in to Firebase with the credential
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Firebase Sign-In failed: \(error.localizedDescription)")
            } else {
                print("User signed in: \(authResult?.user.displayName ?? "No Name")")
            }
        }
    }
}

