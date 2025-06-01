import Foundation
import SwiftUI

struct UserActionCard: View {
    let user: UserSummary
    let actions: [UserAction]
    let onProfileTap: ((String) -> Void)?
    
    @State private var loadingStates: [String: Bool] = [:]
    
    init(
        user: UserSummary,
        actions: [UserAction],
        onProfileTap: ((String) -> Void)? = nil
    ) {
        self.user = user
        self.actions = actions
        self.onProfileTap = onProfileTap
    }
    
    enum Style {
        case primary
        case secondary
        case destructive
        case noAction
    }
    
    class ActionContext: ObservableObject {
        private let actionId: String
        private let completion: (String) -> Void
        
        init(actionId: String, completion: @escaping (String) -> Void) {
            self.actionId = actionId
            self.completion = completion
        }
        
        func actionCompleted() {
            DispatchQueue.main.async {
                self.completion(self.actionId)
            }
        }
    }
    
    struct UserAction {
        let title: String
        let action: ((ActionContext) -> Void)?
        let style: Style
        let width: CGFloat?
        
        init(
            title: String,
            width: CGFloat? = nil,
            variant: Style = .primary,
            action: ((ActionContext) -> Void)? = nil
        ) {
            self.title = title
            self.width = width
            self.style = variant
            self.action = action
        }
    }

    var body: some View {
        VivaCard {
            HStack {
                // User Info
                HStack(spacing: VivaDesign.Spacing.small) {
                    VivaProfileImage(
                        userId: user.id,
                        imageUrl: user.imageUrl,
                        size: .small
                    )
                    .onTapGesture {
                        if let onProfileTap = onProfileTap {
                            onProfileTap(user.id)
                        }
                    }

                    Text(user.displayName)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                        .font(VivaDesign.Typography.body)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: VivaDesign.Spacing.small) {
                    ForEach(actions, id: \.title) { action in
                        let isLoading = loadingStates[action.title] ?? false
                        let color = switch action.style {
                        case .primary:
                            VivaDesign.Colors.vivaGreen
                        case .secondary, .noAction:
                            VivaDesign.Colors.primaryText
                        case .destructive:
                            VivaDesign.Colors.destructive
                        }

                        switch action.style {
                        case .primary, .secondary, .destructive:
                            CardButton(
                                title: isLoading ? "" : action.title,
                                width: action.width,
                                color: color,
                                isLoading: isLoading
                            ) {
                                if !isLoading {
                                    loadingStates[action.title] = true
                                    let context = ActionContext(actionId: action.title) { actionId in
                                        loadingStates[actionId] = false
                                    }
                                    action.action?(context)
                                }
                            }

                        case .noAction:
                            Text(action.title)
                                .foregroundColor(color)
                                .font(VivaDesign.Typography.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
    }
}
