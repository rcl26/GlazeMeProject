import SwiftUI

struct ProfileView: View {
    // Placeholder user data (to be replaced with real data)
    @State private var userName: String = "John Doe"
    @State private var userEmail: String = "john.doe@example.com"
    @State private var profileImage: UIImage? = nil
    @State private var userPlan: String = "Free Trial"  // Added user plan

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
                Text("Name: \(userName)")
                    .font(.custom("Lemonada-Regular", size: 18))
                    .foregroundColor(.black)
                Text("Email: \(userEmail)")
                    .font(.custom("Lemonada-Regular", size: 16))
                    .foregroundColor(.gray)
            }
            .frame(width: 300, alignment: .leading)
            .padding()

            // Divider
            Divider()
                .frame(width: 300)
                .background(Color.blue)

            // User Plan (instead of free uses)
            VStack {
                Text("Current Plan")
                    .font(.custom("Lemonada-Regular", size: 18))
                    .foregroundColor(.black)
                Text("\(userPlan)")  // Display user's current plan
                    .font(.custom("Lemonada-Bold", size: 24))
                    .foregroundColor(userPlan == "Free Trial" ? .green : .blue)
            }

            // Subscription Prompt for Free Plan
            if userPlan == "Free Trial" {
                VStack(spacing: 10) {
                    Text("Your free trial is active!")
                        .font(.custom("Lemonada-Regular", size: 18))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Button(action: {
                        // Add subscription flow here
                        userPlan = "Premium"  // Example: Changing the plan to Premium
                    }) {
                        Text("Subscribe Now")
                            .font(.custom("Lemonada-Bold", size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 20)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}

