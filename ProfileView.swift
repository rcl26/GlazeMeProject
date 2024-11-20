import SwiftUI

struct ProfileView: View {
    // Placeholder user data (to be replaced with real data)
    @State private var userName: String = "John Doe"
    @State private var userEmail: String = "john.doe@example.com"
    @State private var profileImage: UIImage? = nil
    @State private var freeUsesRemaining: Int = 5

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

            // Free Uses Counter
            VStack {
                Text("Free Uses Remaining")
                    .font(.custom("Lemonada-Regular", size: 18))
                    .foregroundColor(.black)
                Text("\(freeUsesRemaining) / 5")
                    .font(.custom("Lemonada-Bold", size: 24))
                    .foregroundColor(freeUsesRemaining > 0 ? .green : .red)
            }

            // Subscription Prompt
            if freeUsesRemaining == 0 {
                VStack(spacing: 10) {
                    Text("You’ve used all your free uses!")
                        .font(.custom("Lemonada-Regular", size: 18))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Button(action: {
                        // Add subscription flow here
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
