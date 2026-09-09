import SwiftUI

// MARK: - Color Palette & Styling Tokens
public extension Color {
    static let appBackground = Color(hex: "0D0E15")
    static let appCardBg = Color(hex: "161923")
    static let appCardBorder = Color.white.opacity(0.12)
    static let appAccentBlue = Color(hex: "3B82F6")
    static let appAccentPurple = Color(hex: "8B5CF6")
    static let appAccentPink = Color(hex: "EC4899")
    static let appYellow = Color(hex: "F59E0B")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom Glassmorphism Modifier
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.appCardBg.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.appCardBorder, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Vibrant Gradient Buttons
public struct PrimaryGradientButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    public init(title: String, icon: String = "play.fill", action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.appAccentBlue, .appAccentPurple, .appAccentPink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .shadow(color: Color.appAccentPurple.opacity(0.5), radius: 10, x: 0, y: 5)
        }
    }
}
