import SwiftUI

struct ErrorBanner: View {
    @ObservedObject var errorManager: ErrorManager
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(errorManager.currentErrors.keys), id: \.self) { errorType in
                if let errorMessage = errorManager.currentErrors[errorType] {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            errorManager.clearError(type: errorType)
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.red)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.default, value: errorManager.currentErrors.count)
    }
} 