import SwiftUI

struct SourcePicker: View {
    @Binding var selectedSource: MovieSource
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(MovieSource.allCases) { source in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSource = source
                    }
                }) {
                    Text(source.rawValue)
                        .font(.footnote)
                        .fontWeight(selectedSource == source ? .bold : .medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedSource == source ?
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(gradient: Gradient(colors: [Color(UIColor.tertiarySystemFill)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(selectedSource == source ? .white : .primary)
                        .cornerRadius(20)
                }
            }
        }
        .padding(.horizontal)
    }
}
