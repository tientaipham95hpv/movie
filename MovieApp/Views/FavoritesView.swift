import SwiftUI

struct FavoritesView: View {
    @State private var favoriteMovies: [UnifiedMovie] = []
    @State private var isLoading = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if favoriteMovies.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Chưa có phim yêu thích")
                            .font(.headline)
                        Text("Nhấn biểu tượng trái tim ở trang chi tiết phim để lưu vào đây.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(favoriteMovies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    MovieCard(movie: movie)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Yêu Thích")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadFavorites()
            }
        }
    }
    
    private func loadFavorites() {
        let favoriteIDs = UserDefaults.standard.stringArray(forKey: "FavoriteMovieIDs") ?? []
        // Note: For persistent offline preview, we can save full metadata or reload
        // Here we read stored IDs
    }
}
