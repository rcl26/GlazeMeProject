import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    // User data fetched from FirebaseAuth
    @State private var userEmail: String = "Loading..."
    @State private var subscriptionPlan: String = "Free" // Default subscription plan
    @State private var profileImage: UIImage? = nil

    // Binding to control modal dismissal
    @Binding var isProfilePresented: Bool

    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Profile Page")
                .font(.custom("Lemonada-Medium", size: 28))
                .foregroundColor(.blue)
                .padding(.top, 30)

            // Profile Image
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .padding(.top, 10)
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }

            // User Details
            VStack(alignment: .leading, spacing: 10) {
                Text("Email: \(userEmail)")
                    .font(.custom("Lemonada-Regular", size: 18))
                    .foregroundColor(.black)
                Text("Subscription Plan: \(subscriptionPlan)")
                    .font(.custom("Lemonada-Regular", size: 16))
                    .foregroundColor(.gray)
            }
            .frame(width: 300, alignment: .leading)
            .padding()

            // Subscribe Now Button (Only for unsubscribed users)
            if subscriptionPlan == "Free" {
                Button(action: subscribeNow) {
                    Text("Subscribe Now")
                        .font(.custom("Lemonada-Bold", size: 18))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
            }

            // Divider
            Divider()
                .frame(width: 300)
                .background(Color.blue)

            Spacer()

            // Buttons (Close and Log Out)
            HStack(spacing: 20) {
                // Close Button
                Button(action: {
                    isProfilePresented = false // Dismiss the profile page
                }) {
                    Text("Close")
                        .font(.custom("Lemonada-Bold", size: 16))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Log Out Button
                Button(action: logOut) {
                    Text("Log Out")
                        .font(.custom("Lemonada-Bold", size: 16))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            fetchUserData() // Fetch user details on appear
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }

    // Fetch user data from FirebaseAuth
    private func fetchUserData() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? "No Email"
            subscriptionPlan = UserDefaults.standard.string(forKey: "subscriptionPlan") ?? "Free"
        }
    }

    // Log Out Logic
    private func logOut() {
        do {
            try Auth.auth().signOut()
            print("User logged out successfully.")
        } catch let error {
            print("Failed to log out: \(error.localizedDescription)")
        }
    }

    // Subscribe Now Logic
    private func subscribeNow() {
        UserDefaults.standard.set("Premium", forKey: "subscriptionPlan")
        subscriptionPlan = "Premium" // Update the local state
        print("Subscription updated to Premium.")
    }
}

