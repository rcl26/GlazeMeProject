import SwiftUI

struct PaywallView: View {
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    var onSubscribe: () -> Void // Callback for when the user chooses to subscribe

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Title
            Text("Your Captions Await!")
                .font(.custom("Lemonada-Bold", size: 30))
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .padding()

            // Description
            Text("$1/week for unlimited access to AI-generated captions.")
                .font(.custom("Lemonada-Regular", size: 18))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            // Subscribe Button
            Button(action: {
                onSubscribe() // Call the subscription action
            }) {
                Text("Subscribe")
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
        .background(Color.black.ignoresSafeArea())
    }
}
