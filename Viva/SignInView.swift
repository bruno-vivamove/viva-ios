//
//  AuthButton.swift
//  Viva
//
//  Created by Bruno Souto on 1/9/25.
//

import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published private(set) var isSignedIn = false  // Make setter private
    
    func signIn() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isSignedIn = true
        }
    }
    
    func signOut() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isSignedIn = false
        }
    }
}

struct SignInView: View {
    private let mainTextFontSize: CGFloat = 70
    private let logoWidth: CGFloat = 180
    private let horizontalPadding: CGFloat = 20
    private let buttonSpacing: CGFloat = 15

    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if authManager.isSignedIn {
                MainView()
                    .environmentObject(authManager)
                    .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 20) {
                    // Logo
                    HStack {
                        Spacer()
                        Image("viva_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: logoWidth)
                            .padding(.trailing, horizontalPadding)
                    }

                    Spacer()

                    // Main Text
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("LONG")
                                .font(.system(size: mainTextFontSize, weight: .bold))
                                .foregroundColor(.vivaGreen)

                            Text("LIVE")
                                .font(.system(size: mainTextFontSize, weight: .bold))
                                .foregroundColor(.vivaGreen)

                            Text("THE FIT")
                                .font(.system(size: mainTextFontSize, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, horizontalPadding)
                    }

                    Spacer()

                    // Buttons
                    VStack(spacing: buttonSpacing) {
                        AuthButton(title: "Sign Up", foregroundColor: .black, backgroundColor: Color.vivaGreen, borderColor: Color.vivaGreen){
                            // Action

                        }
                        
                        AuthButton(title: "Sign In", foregroundColor: .white, backgroundColor: .black, borderColor: .white){
                            self.authManager.signIn()
                        }

                        AuthButton(title: "Sign In", foregroundColor: .white, backgroundColor: .black, borderColor: .white, image: Image("google_logo")){
                            // Action

                        }

                        AuthButton(title: "Sign in with Apple", foregroundColor: .black, backgroundColor: .white, borderColor: .white, image: Image(systemName: "applelogo")
                        ){
                            // Action

                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.vertical, 30)
            }
        }
    }
}

#Preview {
    SignInView()
}
