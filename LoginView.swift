import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var showLogin: Bool = false // Toggle to switch to LoginView
    @State private var isLoggedIn: Bool = false // Navigate after successful sign-up or login
    @State private var hasAgreedToTerms: Bool = false // Tracks Terms of Service agreement
    @State private var showTermsModal: Bool = false // Controls the Terms of Service modal

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

            // Terms of Service Checkbox (Sign Up Only)
            if !showLogin {
                HStack {
                    Button(action: {
                        hasAgreedToTerms.toggle()
                    }) {
                        Image(systemName: hasAgreedToTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(.white)
                    }
                    Text("I agree to the ")
                        .foregroundColor(.white) // Updated for readability
                    Button(action: {
                        showTermsModal.toggle()
                    }) {
                        Text("Terms of Service")
                            .underline()
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }

            // Primary Button (Sign Up or Log In)
            Button(action: {
                if showLogin || hasAgreedToTerms {
                    showLogin ? logIn() : signUp()
                } else {
                    errorMessage = "You must agree to the Terms of Service."
                }
            }) {
                Text(showLogin ? "Log In" : "Sign Up")
                    .font(.custom("Lemonada-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(showLogin ? Color.blue : Color.blue)
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
        .sheet(isPresented: $showTermsModal) {
            TermsOfServiceView()
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
            
            // Initialize subscription status for new users
            UserDefaults.standard.set(false, forKey: "isSubscribed")
            
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
            
            // Fetch subscription status
            let isSubscribed = UserDefaults.standard.bool(forKey: "isSubscribed")
            print("Subscription status: \(isSubscribed ? "Yes" : "No")")
            
            isLoggedIn = true // Navigate after successful login
        }
    }
}

