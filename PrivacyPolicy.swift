import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.custom("Lemonada-Bold", size: 24))
                    .foregroundColor(.blue)
                    .padding(.top, 20)

                Text("Insert your Privacy Policy content here...")
                    .font(.custom("Lemonada-Regular", size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}
