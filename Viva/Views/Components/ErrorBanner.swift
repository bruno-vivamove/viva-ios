import SwiftUI

struct ErrorBanner: View {
    @ObservedObject var errorManager: ErrorManager
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(errorManager.currentErrors.keys), id: \.self) { errorType in
                if let errorMessage = errorManager.currentErrors[errorType] {
                    NotificationBanner(
                        message: errorMessage,
                        errorType: errorType,
                        errorManager: errorManager
                    )
                }
            }
        }
        .padding(.horizontal, VivaDesign.Spacing.screenPadding)
        .padding(.top, 8)
        .animation(.default, value: errorManager.currentErrors.count)
    }
}

struct NotificationBanner: View {
    let message: String
    let errorType: ErrorType
    let errorManager: ErrorManager
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    @State private var appearanceOffset: CGFloat = -100 // Start offscreen
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, VivaDesign.Spacing.medium)
        .padding(.vertical, VivaDesign.Spacing.small)
        .background(VivaDesign.Colors.background)
        .cornerRadius(12)
        .shadow(color: Color.white.opacity(0.6), radius: 2, x: 0, y: 0)
        .offset(y: appearanceOffset - offset) // Combine appearance and swipe offsets
        .onAppear {
            // Animate banner sliding down when appearing
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appearanceOffset = 0
            }
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Only allow upward swipe to dismiss
                    let verticalTranslation = -gesture.translation.height
                    if verticalTranslation > 0 {
                        offset = verticalTranslation
                        isSwiping = true
                    }
                }
                .onEnded { gesture in
                    // If swiped far enough, dismiss the notification
                    if offset > 50 {
                        withAnimation(.easeOut) {
                            offset = 200
                        }
                        // Slight delay before removing to let animation complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            errorManager.clearError(type: errorType)
                        }
                    } else {
                        // Snap back if not swiped far enough
                        withAnimation(.spring()) {
                            offset = 0
                            isSwiping = false
                        }
                    }
                }
        )
    }
} 
