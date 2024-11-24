import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var showSignUp: Bool = false // Toggle to switch to SignUpView
    @State private var isLoggedIn: Bool = false // Toggle to navigate after login

    var body: some View {
        VStack {
            Spacer()

            // Title Text
            Text("Welcome to Glaze Me")
                .font(.custom("Lemonada-Bold", size: 30))
                .foregroundColor(.white)
                .padding(.bottom, 50)

            // Email Input
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
                .padding(.horizontal)

            // Password Input
            SecureField("Password", text: $password)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
                .padding(.horizontal)

            // Log In Button
            Button(action: logIn) {
                Text("Log In")
                    .font(.custom("Lemonada-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
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

            // Sign Up Option
            Button(action: { showSignUp = true }) {
                Text("Don't have an account? Sign Up")
                    .foregroundColor(.white)
                    .underline()
            }
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
        }
        .fullScreenCover(isPresented: $isLoggedIn) {
            ContentView() // Navigate to the main app after login
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

