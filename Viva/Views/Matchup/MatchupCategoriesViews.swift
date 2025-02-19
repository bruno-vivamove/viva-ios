import SwiftUI

struct MatchupCategory: Identifiable {
    let id: String
    let name: String
    var isSelected: Bool
}

struct MatchupCategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coordinator: MatchupCreationCoordinator
    @State private var navigateToMatchupType = false
    @Binding var showCreationFlow: Bool  // Add binding
    @State private var categories: [MatchupCategory] = [
        MatchupCategory(
            id: "calories", name: "Active Calories", isSelected: true),
        MatchupCategory(id: "steps", name: "Steps", isSelected: true),
        MatchupCategory(id: "ehr", name: "eHR Mins", isSelected: true),
        MatchupCategory(
            id: "strength", name: "Strength Training Mins", isSelected: true),
        MatchupCategory(id: "sleep", name: "Sleep Minutes", isSelected: true),
    ]
    
    let userService: UserService

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userService: UserService,
        userSession: UserSession,
        showCreationFlow: Binding<Bool>
    ) {
        self._coordinator = StateObject(
            wrappedValue: MatchupCreationCoordinator(
                matchupService: matchupService,
                friendService: friendService,
                userSession: userSession
            )
        )
        self._showCreationFlow = showCreationFlow
        self.userService = userService
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: VivaDesign.Spacing.medium) {
                    // Title
                    HStack {
                        Text("Choose your ")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            + Text("categories")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(VivaDesign.Colors.vivaGreen)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)

                    // Category Buttons
                    ScrollView {
                        VStack(spacing: VivaDesign.Spacing.small) {
                            ForEach($categories) { $category in
                                Button(action: {
                                    category.isSelected.toggle()
                                }) {
                                    Text(category.name)
                                        .font(
                                            .system(size: 18, weight: .semibold)
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            category.isSelected
                                                ? VivaDesign.Colors.vivaGreen
                                                : Color.clear
                                        )
                                        .foregroundColor(
                                            category.isSelected
                                                ? Color.black : Color.white
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    VivaDesign.Colors.vivaGreen,
                                                    lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Bottom Image
                    Image("runners")  // You'll need to add this image to your assets
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                }
            }
            .navigationDestination(isPresented: $navigateToMatchupType) {
                MatchupTypeView(
                    coordinator: coordinator,
                    showCreationFlow: $showCreationFlow,  // Pass the binding
                    selectedCategories: categories,
                    userService: userService
                )
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Next") {
                        // Verify at least one category is selected
                        if categories.contains(where: { $0.isSelected }) {
                            navigateToMatchupType = true
                        }
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// Preview
#Preview {
    EmptyView()
}
