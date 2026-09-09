import SwiftUI

struct MovieCard: View {
    let movie: UnifiedMovie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray.opacity(0.6))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
                
                // Bottom Gradient Overlay for readability
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .clipped()
                
                // Badges Overlay
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Source Badge
                        Text(movie.source.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                movie.source == .vsphim ?
                                LinearGradient(colors: [Color.appAccentBlue, Color.blue], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color.appAccentPurple, Color.pink], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        
                        Spacer()
                        
                        // Quality Badge
                        if !movie.quality.isEmpty {
                            Text(movie.quality)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.85))
                                .foregroundColor(.appYellow)
                                .cornerRadius(6)
                        }
                    }
                    .padding(6)
                    
                    Spacer()
                    
                    if !movie.year.isEmpty {
                        Text(movie.year)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.bottom, 6)
                    }
                }
            }
            .frame(height: 200)
            .cornerRadius(12)
            .clipped()
            
            // Title Below Image (Fixed 2-line height for aligned grid)
            Text(movie.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 38, alignment: .topLeading)
        }
        .background(Color.appCardBg)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
        .clipped()
    }
}
