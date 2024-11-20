import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile Page")
                .font(.custom("Lemonada-Medium", size: 28))
                .foregroundColor(.blue)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
