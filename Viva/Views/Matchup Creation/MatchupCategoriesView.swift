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
        MatchupCategory(id: "sleep", name: "Sleep Mins", isSelected: false),
    ]
    @State private var isCreatingRematch = false
    
    private var isCategorySelected: Bool {
        return categories.contains(where: { $0.isSelected })
    }

    let userService: UserService
    let source: String
    let rematchMatchupId: String?

    init(
        matchupService: MatchupService,
        friendService: FriendService,
        userService: UserService,
        userSession: UserSession,
        showCreationFlow: Binding<Bool>,
        challengedUser: User? = nil,
        source: String = "default",
        rematchMatchupId: String? = nil
    ) {
        self._coordinator = StateObject(
            wrappedValue: MatchupCreationCoordinator(
                matchupService: matchupService,
                friendService: friendService,
                userSession: userSession,
                challengedUser: challengedUser,
                source: source
            )
        )
        self._showCreationFlow = showCreationFlow
        self.userService = userService
        self.source = source
        self.rematchMatchupId = rematchMatchupId
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
                    userService: userService,
                    source: source
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
                    if rematchMatchupId != nil {
                        Button("Rematch") {
                            createRematch()
                        }
                        .foregroundColor(isCategorySelected ? .white : Color.gray.opacity(0.5))
                        .disabled(!isCategorySelected || isCreatingRematch)
                    } else {
                        Button("Next") {
                            navigateToMatchupType = true
                        }
                        .foregroundColor(isCategorySelected ? .white : Color.gray.opacity(0.5))
                        .disabled(!isCategorySelected)
                    }
                }
            }
            .overlay(
                Group {
                    if isCreatingRematch {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Creating rematch...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.7))
                    }
                }
            )
        }
    }
    
    private func createRematch() {
        guard let matchupId = rematchMatchupId, isCategorySelected, !isCreatingRematch else { return }
        
        let selectedMeasurementTypes = categories
            .filter { $0.isSelected }
            .compactMap { categoryToMeasurementType($0.id) }
        
        guard !selectedMeasurementTypes.isEmpty else { return }
        
        isCreatingRematch = true
        
        let rematchRequest = RematchRequest(
            displayName: "Rematch Challenge",
            measurementTypes: selectedMeasurementTypes
        )
        
        Task {
            do {
                let matchupDetails = try await coordinator.matchupService.rematchMatchup(
                    matchupId: matchupId,
                    rematchRequest: rematchRequest
                )
                await MainActor.run {
                    isCreatingRematch = false
                    showCreationFlow = false
                    
                    // Send a navigation notification with the source
                    NotificationCenter.default.post(
                        name: .homeScreenMatchupCreationCompleted,
                        object: matchupDetails,
                        userInfo: ["source": source]
                    )
                }
            } catch {
                await MainActor.run {
                    isCreatingRematch = false
                    AppLogger.error("Error creating rematch: \(error)")
                }
            }
        }
    }
    
    private func categoryToMeasurementType(_ categoryId: String) -> MeasurementType? {
        switch categoryId {
        case "calories":
            return .energyBurned
        case "steps":
            return .steps
        case "ehr":
            return .elevatedHeartRate
        case "strength":
            return .strengthTraining
        case "sleep":
            return .asleep
        default:
            return nil
        }
    }
}
