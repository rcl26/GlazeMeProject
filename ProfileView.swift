import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var userEmail: String = "Loading..."
    @State private var isSubscribed: String = "No" // Default to "No"
    @Binding var isProfilePresented: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Default Profile Icon
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding(.top, 30)

                // User Details
                VStack(alignment: .leading, spacing: 10) {
                    Text("Account Email: \(userEmail)")
                        .font(.custom("Lemonada-Bold", size: 18))
                        .foregroundColor(.white)
                    Text("Subscribed? \(isSubscribed)")
                        .font(.custom("Lemonada-Bold", size: 18))
                        .foregroundColor(.gray)
                }
                .frame(width: 300, alignment: .leading)
                .padding(.top, 20) // Add spacing below the profile icon

                // Add extra space between User Details and Tappable Options
                Spacer()
                    .frame(height: 30) // Adjust height as needed
                
                // Tappable Options
                VStack(spacing: 15) {
                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("Terms of Service")
                            .font(.custom("Lemonada-Regular", size: 14))
                            .foregroundColor(.gray)
                            .underline()
                    }

                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                            .font(.custom("Lemonada-Regular", size: 14))
                            .foregroundColor(.gray)
                            .underline()
                    }

                    NavigationLink(destination: DisclaimerView()) {
                        Text("Disclaimer")
                            .font(.custom("Lemonada-Regular", size: 14))
                            .foregroundColor(.gray)
                            .underline()
                    }

                    Button(action: logOut) {
                        Text("Log Out")
                            .font(.custom("Lemonada-Regular", size: 14))
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
            .background(Color.black.ignoresSafeArea())
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

