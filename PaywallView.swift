import SwiftUI

struct PaywallView: View {
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    var onSubscribe: () -> Void // Callback for when the user chooses to subscribe

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Title
            Text("Unlock Premium Features!")
                .font(.custom("Lemonada-Bold", size: 30))
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .padding()

            // Description
            Text("Gain unlimited access to AI-generated compliments and more by subscribing to our premium plan.")
                .font(.custom("Lemonada-Regular", size: 18))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            // Subscribe Button
            Button(action: {
                onSubscribe() // Call the subscription action
            }) {
                Text("Subscribe Now")
                    .font(.custom("Lemonada-Bold", size: 20))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }

            // Dismiss Button
            Button(action: {
                presentationMode.wrappedValue.dismiss() // Dismiss the paywall
            }) {
                Text("Not Now")
                    .font(.custom("Lemonada-Regular", size: 18))
                    .foregroundColor(.blue)
                    .padding()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}
