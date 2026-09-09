import SwiftUI

struct MovieCard: View {
    let movie: UnifiedMovie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: movie.thumbURL.isEmpty ? movie.posterURL : movie.thumbURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "film")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 200)
                .cornerRadius(12)
                .clipped()
                
                // Source & Quality Badge
                HStack(spacing: 4) {
                    Text(movie.source.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(movie.source == .vsphim ? Color.blue.opacity(0.85) : Color.purple.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    
                    if !movie.quality.isEmpty {
                        Text(movie.quality)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.75))
                            .foregroundColor(.yellow)
                            .cornerRadius(6)
                    }
                }
                .padding(6)
            }
            
            Text(movie.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            if !movie.year.isEmpty {
                Text(movie.year)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
        .cornerRadius(12)
    }
}
