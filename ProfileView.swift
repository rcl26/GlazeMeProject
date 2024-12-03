import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var userEmail: String = "Loading..."
    @State private var isSubscribed: String = "No" // Default to "No"
    @Binding var isProfilePresented: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Profile Title
                Text("Profile")
                    .font(.custom("Lemonada-Medium", size: 28))
                    .foregroundColor(.blue)
                    .padding(.top, 30)

                // User Details
                VStack(alignment: .leading, spacing: 10) {
                    Text("Email: \(userEmail)")
                        .font(.custom("Lemonada-Regular", size: 14))
                        .foregroundColor(.black)
                    Text("Subscribed? \(isSubscribed)")
                        .font(.custom("Lemonada-Regular", size: 14))
                        .foregroundColor(.gray)
                }
                .frame(width: 300, alignment: .leading)
                .padding()

                // Tappable Options
                VStack(spacing: 15) {
                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("Terms of Service")
                            .font(.custom("Lemonada-Bold", size: 16))
                            .foregroundColor(.gray)
                            .underline()
                    }

                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                            .font(.custom("Lemonada-Bold", size: 16))
                            .foregroundColor(.gray)
                            .underline()
                    }

                    NavigationLink(destination: DisclaimerView()) {
                        Text("Disclaimer")
                            .font(.custom("Lemonada-Bold", size: 16))
                            .foregroundColor(.gray)
                            .underline()
                    }

                    Button(action: logOut) {
                        Text("Log Out")
                            .font(.custom("Lemonada-Bold", size: 16))
                            .foregroundColor(.gray)
                            .underline()
                    }

                    Button(action: {
                        sendSupportEmail()
                    }) {
                        Text("Email us!")
                            .font(.custom("Lemonada-Bold", size: 16))
                            .foregroundColor(.blue)
                            .underline()
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .onAppear {
                fetchUserData()
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
        }
    }

    private func fetchUserData() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? "No Email"
            let isSubscribedBool = UserDefaults.standard.bool(forKey: "isSubscribed")
            isSubscribed = isSubscribedBool ? "Yes" : "No"
        }
    }

    private func logOut() {
        do {
            try Auth.auth().signOut()
            print("User logged out successfully.")
        } catch let error {
            print("Failed to log out: \(error.localizedDescription)")
        }
    }

    private func sendSupportEmail() {
        let email = "mailto:placeholder@capcall.com?subject=Support%20Request&body=Describe%20your%20request%20or%20feature%20suggestion%20here."
        if let url = URL(string: email) {
            UIApplication.shared.open(url)
        } else {
            print("Failed to open email client.")
        }
    }
}

