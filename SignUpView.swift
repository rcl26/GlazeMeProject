import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    var body: some View {
        VStack {
            Spacer()

            // Title Text
            Text("Create an Account")
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

            // Sign Up Button
            Button(action: signUp) {
                Text("Sign Up")
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

            // Back to Login
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Already have an account? Log In")
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
    }

    // Firebase Sign Up Logic
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Sign-up failed: \(error.localizedDescription)"
                return
            }
            print("User signed up: \(result?.user.email ?? "No Email")")
            
            // Initialize subscription status for new users
            UserDefaults.standard.set(false, forKey: "isSubscribed")
            
            // Dismiss sign-up view
            presentationMode.wrappedValue.dismiss()
        }
    }

}

