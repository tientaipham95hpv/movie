import SwiftUI

struct FavoritesView: View {
    @State private var favoriteMovies: [UnifiedMovie] = []
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 14) {
                    // Header
                    HStack {
                        Text("Phim Yêu Thích")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if favoriteMovies.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.appCardBg)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 36))
                                    .foregroundColor(.appAccentPink)
                            }
                            Text("Chưa Có Phim Yêu Thích")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Nhấn vào biểu tượng trái tim ở trang chi tiết phim để lưu bộ phim bạn yêu thích vào đây.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(favoriteMovies) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        MovieCard(movie: movie)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadFavorites()
            }
        }
    }
    
    private func loadFavorites() {
        let _ = UserDefaults.standard.stringArray(forKey: "FavoriteMovieIDs") ?? []
    }
}
