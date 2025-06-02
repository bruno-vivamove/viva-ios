import SwiftUI

struct MatchupTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var coordinator: MatchupCreationCoordinator
    @Binding var showCreationFlow: Bool
    @State private var matchupCreated: MatchupDetails?
    @State private var navigateToInvite = false
    let selectedCategories: [MatchupCategory]
    let userService: UserService
    let source: String

    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                // Header
                HStack {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()

                    Spacer()
                }

                // Main content
                VStack(spacing: VivaDesign.Spacing.xlarge) {
                    // Type Selection Buttons
                    VStack(spacing: VivaDesign.Spacing.large) {
                        VivaButton(
                            title: "1v1",
                            size: .large,
                            style: .secondary,
                            isLoading: coordinator.isCreatingMatchup
                        ) {
                            Task {
                                matchupCreated =
                                    await coordinator.createMatchup(
                                        selectedCategories: selectedCategories,
                                        usersPerSide: 1
                                    )
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, VivaDesign.Spacing.large)

                Spacer()
                // Footer Logo
                Image("viva_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                    .padding(.bottom, VivaDesign.Spacing.xlarge)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToInvite) {
            if let matchup = matchupCreated, coordinator.challengedUser == nil {
                // Only show invite view if there's no challenged user
                MatchupInviteView(
                    matchupService: coordinator.matchupService,
                    friendService: coordinator.friendService,
                    userService: userService,
                    userSession: coordinator.userSession,
                    matchup: matchup,
                    usersPerSide: matchup.usersPerSide,
                    showCreationFlow: $showCreationFlow,
                    source: source
                )
            }
        }
        .alert("Error", isPresented: .constant(coordinator.error != nil)) {
            Button("OK") {
                coordinator.error = nil
            }
        } message: {
            if let error = coordinator.error {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: matchupCreated != nil) { wasCreated, isCreated in
            if isCreated {
                if coordinator.challengedUser != nil {
                    // If there's a challenged user, close the flow and notify
                    showCreationFlow = false
                    if let matchupCreated = self.matchupCreated {
                        NotificationCenter.default.post(
                            name: .matchupCreationFlowCompleted,
                            object: matchupCreated,
                            userInfo: ["source": source]
                        )
                    }
                } else {
                    // Otherwise, show the invite view
                    navigateToInvite = true
                }
            }
        }
    }
}

struct MatchupTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 1)
                )
        }
    }
}
