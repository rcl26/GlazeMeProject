import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Privacy Policy")
                    .font(.title) // Default system font
                    .bold()
                    .foregroundColor(.blue)
                    .padding(.top, 20)

                // Privacy Policy Content
                Text("""
                Last updated: [Insert Date]

                At Cap Call ("we," "our," or "us"), we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your personal information when you use our mobile application ("App") and associated services ("Services").

                By using the App, you consent to the practices described in this policy.

                1. Information We Collect
                We collect the following types of information:

                - Account Information:
                  When you create an account, we collect your email address and password. Account details cannot be changed after registration.

                - Uploaded Images:
                  Images uploaded to the App are used solely for processing captions via Google Vision API and OpenAI's GPT-4. These images are not stored long-term and are deleted after processing.

                - Usage Data:
                  We collect anonymous data about how you use the App, including feature usage, timestamps, and error reports, in line with Firebase’s standard practices.

                - Device Information:
                  We may collect information about your device, such as operating system, device type, and unique device identifiers, to improve App functionality and security.

                2. How We Use Your Information
                We use the information we collect to:
                - Process uploaded images and generate captions.
                - Monitor and analyze usage trends and performance.
                - Respond to customer support inquiries.
                - Comply with legal obligations and enforce our Terms of Service.

                3. Third-Party Services
                We use the following third-party services:
                - Google Vision API: For processing uploaded images, including SafeSearch for inappropriate content detection.
                - OpenAI's GPT-4: For generating captions based on user input and images.
                - Firebase: For authentication, analytics, and temporary storage of data.

                These services have their own privacy practices. By using the App, you also agree to the data handling practices of these third-party services.

                4. Data Retention
                - Uploaded images are deleted immediately after processing.
                - Minimal data, such as compliance logs and payment records, may be retained for up to 180 days to comply with operational or legal requirements.

                5. Your Rights
                You have the right to:
                - Access Your Data: Request a copy of your personal data.
                - Delete Your Account: Email us at [Insert Email Address] to request the deletion of your account and associated data.

                6. Security of Your Information
                We take reasonable measures to protect your personal information from unauthorized access, loss, or misuse. However, no security system is completely foolproof, and we cannot guarantee the absolute security of your data.

                7. Children’s Privacy
                The App is not intended for children under 13. We do not knowingly collect personal information from users under 13 years old.

                8. Changes to This Privacy Policy
                We may update this Privacy Policy from time to time. Changes will be effective upon posting in the App. Continued use of the App after updates signifies your acceptance of the revised policy.

                9. Contact Us
                If you have any questions about this Privacy Policy, please contact us at [Insert Email Address].
                """)
                .font(.body) // Default system font for readability
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 20)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

