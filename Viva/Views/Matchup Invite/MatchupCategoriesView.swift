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
    @Binding var showCreationFlow: Bool
    @State private var categories: [MatchupCategory] = [
        MatchupCategory(id: "calories", name: "Active Calories", isSelected: false),
        MatchupCategory(id: "steps", name: "Steps", isSelected: false),
        MatchupCategory(id: "ehr", name: "eHR Mins", isSelected: false),
        MatchupCategory(id: "strength", name: "Strength Training Mins", isSelected: false),
        MatchupCategory(id: "sleep", name: "Sleep Minutes", isSelected: false),
    ]
    
    private var isCategorySelected: Bool {
        return categories.contains(where: { $0.isSelected })
    }

    let userService: UserService

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userService: UserService,
        userSession: UserSession,
        showCreationFlow: Binding<Bool>,
        challengedUser: User? = nil
    ) {
        self._coordinator = StateObject(
            wrappedValue: MatchupCreationCoordinator(
                matchupService: matchupService,
                friendService: friendService,
                userSession: userSession,
                challengedUser: challengedUser
            )
        )
        self._showCreationFlow = showCreationFlow
        self.userService = userService
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: VivaDesign.Spacing.medium) {
                // Title
                Text("Choose your ")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    + Text("categories")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
                
                // Category List
                ScrollView {
                    VStack(spacing: VivaDesign.Spacing.small) {
                        ForEach($categories) { $category in
                            Button(action: {
                                category.isSelected.toggle()
                            }) {
                                Text(category.name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(category.isSelected ? VivaDesign.Colors.vivaGreen : Color.clear)
                                    )
                                    .foregroundColor(category.isSelected ? Color.black : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(VivaDesign.Colors.vivaGreen, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }

                // Select All Button
                Button(action: {
                    let allSelected = categories.allSatisfy { $0.isSelected }
                    for i in 0..<categories.count {
                        categories[i].isSelected = !allSelected
                    }
                }) {
                    Text(categories.allSatisfy { $0.isSelected } ? "Deselect All" : "Select All")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, VivaDesign.Spacing.medium)
                        .padding(.vertical, VivaDesign.Spacing.small)
                        .background(Color.clear)
                        .foregroundColor(VivaDesign.Colors.vivaGreen)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(VivaDesign.Colors.vivaGreen, lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationDestination(isPresented: $navigateToMatchupType) {
                MatchupTypeView(
                    coordinator: coordinator,
                    showCreationFlow: $showCreationFlow,
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
                        navigateToMatchupType = true
                    }
                    .foregroundColor(isCategorySelected ? .white : Color.gray.opacity(0.5))
                    .disabled(!isCategorySelected)
                }
            }
        }
    }
}
