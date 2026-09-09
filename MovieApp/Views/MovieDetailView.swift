import SwiftUI

struct MovieDetailView: View {
    let initialMovie: UnifiedMovie
    @State private var movie: UnifiedMovie
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedEpisode: UnifiedEpisode?
    @State private var isFavorite = false
    @State private var isPlaying = false
    
    init(movie: UnifiedMovie) {
        self.initialMovie = movie
        self._movie = State(initialValue: movie)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Poster Image / Player Trigger
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: movie.posterURL.isEmpty ? movie.thumbURL : movie.posterURL)) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                               .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle()
                               .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(height: 280)
                    .clipped()
                    .overlay(
                        LinearGradient(gradient: Gradient(colors: [.clear, Color(UIColor.systemBackground)]), startPoint: .center, endPoint: .bottom)
                    )
                    
                    if let firstEp = movie.episodes.first {
                        Button(action: {
                            selectedEpisode = firstEp
                            isPlaying = true
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                Text("Xem Ngay")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Title & Favorites
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(movie.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if !movie.originalTitle.isEmpty {
                                Text(movie.originalTitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        
                        Button(action: toggleFavorite) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(isFavorite ? .red : .gray)
                        }
                    }
                    
                    // Metadata tags
                    HStack(spacing: 8) {
                        Text(movie.source.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(movie.source == .vsphim ? Color.blue : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        
                        if !movie.quality.isEmpty {
                            Text(movie.quality)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.85))
                                .foregroundColor(.black)
                                .cornerRadius(6)
                        }
                        
                        if !movie.year.isEmpty {
                            Text(movie.year)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    if !movie.category.isEmpty {
                        Text("Thể loại: \(movie.category.joined(separator: ", "))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    if !movie.actor.isEmpty {
                        Text("Diễn viên: \(movie.actor.joined(separator: ", "))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    // Episodes List
                    if !movie.episodes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Danh Sách Tập (\(movie.episodes.count))")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                                ForEach(movie.episodes) { ep in
                                    Button(action: {
                                        selectedEpisode = ep
                                        isPlaying = true
                                    }) {
                                        Text(ep.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(selectedEpisode?.id == ep.id ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedEpisode?.id == ep.id ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Description
                    if !movie.description.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nội Dung Phim")
                                .font(.headline)
                            Text(movie.description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkFavoriteStatus()
            loadDetail()
        }
        .fullScreenCover(isPresented: $isPlaying) {
            if let ep = selectedEpisode {
                PlayerScreenView(episode: ep, movieTitle: movie.title)
            }
        }
    }
    
    private func loadDetail() {
        Task {
            do {
                let detailed = try await APIService.shared.fetchMovieDetail(movie: initialMovie)
                await MainActor.run {
                    self.movie = detailed
                    if self.selectedEpisode == nil {
                        self.selectedEpisode = detailed.episodes.first
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func checkFavoriteStatus() {
        let favorites = getFavoriteIDs()
        isFavorite = favorites.contains(movie.id)
    }
    
    private func toggleFavorite() {
        var favorites = getFavoriteIDs()
        if isFavorite {
            favorites.remove(movie.id)
        } else {
            favorites.insert(movie.id)
        }
        UserDefaults.standard.set(Array(favorites), forKey: "FavoriteMovieIDs")
        isFavorite.toggle()
    }
    
    private func getFavoriteIDs() -> Set<String> {
        let arr = UserDefaults.standard.stringArray(forKey: "FavoriteMovieIDs") ?? []
        return Set(arr)
    }
}
