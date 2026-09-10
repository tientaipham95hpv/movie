import SwiftUI

// MARK: - Shimmer Effect Modifier
public struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.6
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.white.opacity(0.12), location: 0.5),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .offset(x: geo.size.width * phase)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.6
                }
            }
    }
}

public extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Movie Card for Loading States
public struct SkeletonMovieCard: View {
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appCardBg)
                .frame(height: 180)
                .shimmer()
            
            // Title line 1
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.appCardBg)
                .frame(height: 12)
                .padding(.horizontal, 6)
                .shimmer()
            
            // Title line 2
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.appCardBg)
                .frame(width: 80, height: 10)
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
                .shimmer()
        }
        .background(Color.appCardBg.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
    }
}
