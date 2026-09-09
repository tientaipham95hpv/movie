import SwiftUI

struct MovieCard: View {
    let movie: UnifiedMovie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                // Poster Image
                AsyncImage(url: URL(string: movie.thumbURL.isEmpty ? movie.posterURL : movie.thumbURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.appCardBg)
                            .overlay(ProgressView().tint(.white))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.appCardBg)
                            .overlay(
                                Image(systemName: "film")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray.opacity(0.6))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 220)
                .clipped()
                .cornerRadius(14)
                
                // Bottom Gradient Overlay for readability
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(14)
                
                // Badges Overlay (Top Right & Bottom Left)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Source Badge
                        Text(movie.source.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                movie.source == .vsphim ?
                                LinearGradient(colors: [Color.appAccentBlue, Color.blue], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color.appAccentPurple, Color.pink], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 4)
                        
                        Spacer()
                        
                        // Quality Badge
                        if !movie.quality.isEmpty {
                            Text(movie.quality)
                                .font(.system(size: 9, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.85))
                                .foregroundColor(.appYellow)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.appYellow.opacity(0.4), lineWidth: 1)
                                )
                        }
                    }
                    .padding(8)
                    
                    Spacer()
                    
                    // Year Badge
                    if !movie.year.isEmpty {
                        Text(movie.year)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.bottom, 6)
                    }
                }
            }
            .frame(height: 220)
            
            // Title
            Text(movie.title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
        }
        .glassCard(cornerRadius: 16)
    }
}
