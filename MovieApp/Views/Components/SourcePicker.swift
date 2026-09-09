import SwiftUI

struct SourcePicker: View {
    @Binding var selectedSource: MovieSource
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(MovieSource.allCases) { source in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedSource = source
                    }
                }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(sourceColor(source))
                            .frame(width: 6, height: 6)
                        
                        Text(source.rawValue)
                            .font(.system(size: 13, weight: selectedSource == source ? .bold : .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            if selectedSource == source {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.appAccentBlue, Color.appAccentPurple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.appAccentPurple.opacity(0.4), radius: 6, x: 0, y: 3)
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.appCardBg.opacity(0.6))
                            }
                        }
                    )
                    .foregroundColor(selectedSource == source ? .white : .gray)
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.3))
        .cornerRadius(24)
        .padding(.horizontal)
    }
    
    private func sourceColor(_ source: MovieSource) -> Color {
        switch source {
        case .all: return .appYellow
        case .vsphim: return .appAccentBlue
        case .avdb: return .appAccentPurple
        }
    }
}
