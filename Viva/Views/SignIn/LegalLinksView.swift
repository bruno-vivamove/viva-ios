import SwiftUI

struct LegalLinksView: View {
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                HStack(spacing: 0) {
                    Text("By signing up, you are agreeing to our ")
                        .font(.system(size: 12))
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                    
                    Button("Terms of Use") {
                        showingTerms = true
                    }
                    .font(.system(size: 12))
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    
                    Text(".")
                        .font(.system(size: 12))
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
                
                HStack(spacing: 0) {
                    Text("View ")
                        .font(.system(size: 12))
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                    
                    Button("Privacy Policy") {
                        showingPrivacy = true
                    }
                    .font(.system(size: 12))
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                    
                    Text(".")
                        .font(.system(size: 12))
                        .foregroundColor(VivaDesign.Colors.secondaryText)
                }
            }
            Spacer()
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfUseView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }
}
