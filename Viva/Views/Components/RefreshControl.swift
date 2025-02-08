import SwiftUI

struct RefreshControl: View {
    let coordinateSpace: CoordinateSpace
    let onRefresh: () async -> Void
    
    @State private var isRefreshing = false
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: coordinateSpace).midY > 50 {
                Spacer()
                    .onAppear {
                        guard !isRefreshing else { return }
                        isRefreshing = true
                        Task {
                            await onRefresh()
                            isRefreshing = false
                        }
                    }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                }
                Spacer()
            }
            .offset(y: min(geometry.frame(in: coordinateSpace).midY - 30, 0))
        }
        .frame(height: 0)
    }
}
