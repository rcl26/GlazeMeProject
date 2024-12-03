import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.custom("Lemonada-Bold", size: 24))
                    .foregroundColor(.blue)
                    .padding(.top, 20)

                Text("Insert your Terms of Service content here...")
                    .font(.custom("Lemonada-Regular", size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
}
