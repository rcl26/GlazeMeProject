import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var showLogin: Bool = false // Toggle to switch to LoginView
    @State private var isLoggedIn: Bool = false // Navigate after successful sign-up or login

    var body: some View {
        VStack {
            Spacer()

            // Title Text
            Text(showLogin ? "Welcome Back" : "Create an Account")
                .font(.custom("Lemonada-Bold", size: 30))
                .foregroundColor(.white)
                .padding(.bottom, 50)

            // Email Input
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
                .tint(.white)
                .foregroundColor(.white)
                .padding(.horizontal)

            // Password Input
            SecureField("Password", text: $password)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
                .tint(.white)
                .foregroundColor(.white)
                .padding(.horizontal)

            // Primary Button (Sign Up or Log In)
            Button(action: showLogin ? logIn : signUp) {
                Text(showLogin ? "Log In" : "Sign Up")
                    .font(.custom("Lemonada-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(showLogin ? Color.green : Color.blue)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            // Error Message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.custom("Lemonada-Regular", size: 16))
                    .padding(.top, 10)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Toggle Between Log In and Sign Up
            Button(action: { showLogin.toggle() }) {
                Text(showLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                    .foregroundColor(.white)
                    .underline()
            }
            .padding(.bottom, 60)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $isLoggedIn) {
            ContentView() // Navigate to the main app after sign-up or login
        }
    }

    // Firebase Sign Up Logic
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Sign Up failed: \(error.localizedDescription)"
                return
            }
            print("User signed up: \(result?.user.email ?? "No Email")")
            isLoggedIn = true // Navigate after successful sign-up
        }
    }

    // Firebase Log In Logic
    private func logIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Login failed: \(error.localizedDescription)"
                return
            }
            print("User logged in: \(result?.user.email ?? "No Email")")
            isLoggedIn = true // Navigate after successful login
        }
    }
}

