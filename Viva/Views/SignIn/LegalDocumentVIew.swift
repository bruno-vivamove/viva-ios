import SwiftUI

struct LegalDocumentView: View {
    let title: String
    let content: [LegalSection]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VivaDesign.Spacing.large) {
                    ForEach(content) { section in
                        VStack(alignment: .leading, spacing: VivaDesign.Spacing.medium) {
                            Text(section.title)
                                .font(.headline)
                                .foregroundColor(VivaDesign.Colors.primaryText)
                            
                            Text(section.content)
                                .font(.body)
                                .foregroundColor(VivaDesign.Colors.secondaryText)
                        }
                    }
                }
                .padding(VivaDesign.Spacing.large)
            }
            .background(VivaDesign.Colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(VivaDesign.Colors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                }
            }
            .toolbarBackground(VivaDesign.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

struct TermsOfUseView: View {
    var body: some View {
        LegalDocumentView(
            title: "Terms of Use",
            content: [
                LegalSection(
                    title: "1. Acceptance of Terms",
                    content: "By accessing and using the Viva app, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the app."
                ),
                LegalSection(
                    title: "2. User Accounts",
                    content: "You must create an account to use Viva. You are responsible for maintaining the confidentiality of your account information and for all activities under your account. You must provide accurate and complete information when creating your account."
                ),
                LegalSection(
                    title: "3. Fitness Activities",
                    content: "Viva provides fitness tracking and social features. You acknowledge that participating in physical activities carries inherent risks. You are solely responsible for your decision to engage in or refrain from physical activities."
                ),
                LegalSection(
                    title: "4. User Content",
                    content: "You retain ownership of content you share through Viva. By posting content, you grant Viva a non-exclusive license to use, display, and distribute that content for app functionality purposes."
                ),
                LegalSection(
                    title: "5. Prohibited Activities",
                    content: "You agree not to: (a) violate any laws; (b) impersonate others; (c) post harmful content; (d) interfere with app functionality; (e) attempt to gain unauthorized access to systems or data."
                ),
                LegalSection(
                    title: "6. Intellectual Property",
                    content: "Viva and its original content are protected by copyright, trademark, and other laws. Our trademarks and visual elements may not be used without express permission."
                ),
                LegalSection(
                    title: "7. Termination",
                    content: "We may suspend or terminate your account for violations of these terms. You may terminate your account at any time through the app settings."
                ),
                LegalSection(
                    title: "8. Changes to Terms",
                    content: "We may modify these terms at any time. Continued use of Viva after changes constitutes acceptance of modified terms."
                ),
                LegalSection(
                    title: "9. Disclaimer",
                    content: "Viva is provided 'as is' without warranties. We are not responsible for accuracy of fitness data or user-generated content."
                ),
                LegalSection(
                    title: "10. Limitation of Liability",
                    content: "To the maximum extent permitted by law, Viva shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the service."
                )
            ]
        )
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocumentView(
            title: "Privacy Policy",
            content: [
                LegalSection(
                    title: "Information We Collect",
                    content: "We collect information you provide (name, email, profile data) and automatically collected data (device info, usage data, fitness metrics). We use fitness tracking features that require activity permissions."
                ),
                LegalSection(
                    title: "How We Use Your Information",
                    content: "We use your information to: provide app functionality, process your requests, send notifications, improve our services, and ensure security. Fitness data is used to track progress and enable social features."
                ),
                LegalSection(
                    title: "Information Sharing",
                    content: "We share information with: other users based on your privacy settings, service providers who assist our operations, and when required by law. We do not sell your personal information."
                ),
                LegalSection(
                    title: "Data Security",
                    content: "We implement appropriate security measures to protect your information. However, no method of transmission over the internet is 100% secure."
                ),
                LegalSection(
                    title: "Your Rights",
                    content: "You can access, update, or delete your account information through the app settings. You control privacy settings for sharing fitness data and activity with other users."
                ),
                LegalSection(
                    title: "Third-Party Services",
                    content: "We may integrate with third-party fitness services. Their use of your information is governed by their privacy policies."
                ),
                LegalSection(
                    title: "Data Retention",
                    content: "We retain your information as long as your account is active or as needed to provide services. You may request deletion of your account at any time."
                ),
                LegalSection(
                    title: "Children's Privacy",
                    content: "Viva is not intended for children under 13. We do not knowingly collect information from children under 13."
                ),
                LegalSection(
                    title: "Changes to Policy",
                    content: "We may update this privacy policy. We will notify you of material changes via email or app notification."
                ),
                LegalSection(
                    title: "Contact Us",
                    content: "If you have questions about this privacy policy or your data, contact us at privacy@vivamove.com"
                )
            ]
        )
    }
}

#Preview {
    TermsOfUseView()
}
