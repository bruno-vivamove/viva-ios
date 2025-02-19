import SwiftUI

struct MatchupTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var coordinator: MatchupCreationCoordinator
    @Binding var showCreationFlow: Bool
    @State private var matchupCreated: MatchupDetails?
    @State private var navigateToInvite = false
    let selectedCategories: [MatchupCategory]
    let userService: UserService

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
                        Button(action: {
                            Task {
                                await createMatchup(usersPerSide: 1)
                            }
                        }) {
                            Text("1v1")
                                .font(.system(size: 24, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, VivaDesign.Spacing.large)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }

                        //                        Button(action: {
                        //                            Task {
                        //                                await createMatchup(usersPerSide: 2)
                        //                            }
                        //                        }) {
                        //                            Text("2v2")
                        //                                .font(.system(size: 24, weight: .semibold))
                        //                                .frame(maxWidth: .infinity)
                        //                                .padding(.vertical, VivaDesign.Spacing.large)
                        //                                .foregroundColor(.white)
                        //                                .overlay(
                        //                                    RoundedRectangle(cornerRadius: 8)
                        //                                        .stroke(Color.white, lineWidth: 1)
                        //                                )
                        //                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, VivaDesign.Spacing.large)

                // Footer Logo
                HStack(spacing: VivaDesign.Spacing.small) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundColor(VivaDesign.Colors.vivaGreen)

                    Text("VIVA")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 40)
            }

            if coordinator.isCreatingMatchup {
                ProgressView()
                    .tint(.white)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToInvite) {
            if let matchup = matchupCreated {
                MatchupInviteView(
                    matchupService: coordinator.matchupService,
                    friendService: coordinator.friendService,
                    userService: userService,
                    userSession: coordinator.userSession,
                    matchupId: matchup.id,
                    usersPerSide: matchup.usersPerSide,
                    showCreationFlow: $showCreationFlow
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
                navigateToInvite = true
            }
        }
    }

    private func createMatchup(usersPerSide: Int) async {
        matchupCreated = await coordinator.createMatchup(
            selectedCategories: selectedCategories,
            usersPerSide: usersPerSide
        )
    }
}

// Preview
#Preview {
    let userSession = VivaAppObjects.dummyUserSession()
    let vivaAppObjects = VivaAppObjects(userSession: userSession)
    let networkClient = NetworkClient(
        settings: AppNetworkClientSettings(userSession: userSession))
    let matchupService = MatchupService(networkClient: networkClient)
    let friendService = FriendService(networkClient: networkClient)

    MatchupTypeView(
        coordinator: MatchupCreationCoordinator(
            matchupService: matchupService,
            friendService: friendService,
            userSession: userSession
        ),
        showCreationFlow: .constant(true),
        selectedCategories: [
            MatchupCategory(id: "steps", name: "Steps", isSelected: true),
            MatchupCategory(
                id: "calories", name: "Active Calories", isSelected: true),
        ], userService: vivaAppObjects.userService
    )
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

struct MatchupTypeView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
