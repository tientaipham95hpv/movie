import SwiftUI

struct MovieCard: View {
    let movie: UnifiedMovie
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Poster Container with fixed Geometry bounds
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    CachedAsyncImage(urlString: movie.thumbURL.isEmpty ? movie.posterURL : movie.thumbURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: 180)
                            .clipped()
                    } placeholder: {
                        ZStack {
                            Color.appCardBg
                            VStack(spacing: 8) {
                                Image(systemName: "film")
                                    .font(.system(size: 26))
                                    .foregroundColor(.appAccentPurple.opacity(0.8))
                                Text(movie.title)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 6)
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: 180)
                    .clipped()
                    
                    // Bottom Gradient
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: geo.size.width, height: 180)
                    
                    // Top Badges & Quick Favorite Button
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(movie.source.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    movie.source == .vsphim ?
                                    LinearGradient(colors: [Color.appAccentBlue, Color.blue], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color.appAccentPurple, Color.pink], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(5)
                            
                            Spacer()
                            
                            // Quick Favorite Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    FavoritesService.shared.toggleFavorite(movie: movie)
                                    isFavorite = FavoritesService.shared.isFavorite(movieID: movie.id)
                                }
                            }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isFavorite ? .appAccentPink : .white.opacity(0.8))
                                    .padding(5)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            if !movie.quality.isEmpty {
                                Text(movie.quality)
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.85))
                                    .foregroundColor(.appYellow)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(5)
                        
                        Spacer()
                        
                        if !movie.year.isEmpty {
                            Text(movie.year)
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.bottom, 4)
                        }
                    }
                }
            }
            .frame(height: 180)
            .cornerRadius(10)
            .clipped()
            
            // Title Below Poster
            Text(movie.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 32, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .background(Color.appCardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
        .clipped()
        .onAppear {
            isFavorite = FavoritesService.shared.isFavorite(movieID: movie.id)
        }
    }
}
