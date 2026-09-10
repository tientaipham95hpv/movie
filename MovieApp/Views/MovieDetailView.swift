import SwiftUI

struct MovieDetailView: View {
    let initialMovie: UnifiedMovie
    @State private var movie: UnifiedMovie
    @State private var isLoading = true
    @State private var selectedEpisode: UnifiedEpisode?
    @State private var isFavorite = false
    @State private var isPlaying = false
    @State private var relatedMovies: [UnifiedMovie] = []
    
    init(movie: UnifiedMovie) {
        self.initialMovie = movie
        self._movie = State(initialValue: movie)
    }
    
    private var cleanDescription: String {
        let text = movie.description
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "Đang cập nhật nội dung..." : text
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero Poster Backdrop Banner
                    ZStack(alignment: .bottomLeading) {
                        GeometryReader { geo in
                            CachedAsyncImage(urlString: movie.posterURL.isEmpty ? movie.thumbURL : movie.posterURL) { img in
                                img.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: 300)
                                    .clipped()
                            } placeholder: {
                                Rectangle().fill(Color.appCardBg)
                            }
                        }
                        .frame(height: 300)
                        .overlay(
                            LinearGradient(
                                colors: [.clear, Color.appBackground.opacity(0.6), Color.appBackground],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // Floating Hero Meta
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(movie.source.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(movie.source == .vsphim ? Color.appAccentBlue : Color.appAccentPurple)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                
                                if !movie.quality.isEmpty {
                                    Text(movie.quality)
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.8))
                                        .foregroundColor(.appYellow)
                                        .cornerRadius(6)
                                }
                                
                                if !movie.year.isEmpty {
                                    Text(movie.year)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Text(movie.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if !movie.originalTitle.isEmpty {
                                Text(movie.originalTitle)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                    
                    // Main Action Buttons (Play / Favorite / Download)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            if let firstEp = movie.episodes.first {
                                Button(action: {
                                    if selectedEpisode == nil { selectedEpisode = firstEp }
                                    isPlaying = true
                                }) {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Xem Phim")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(colors: [.appAccentBlue, .appAccentPurple], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.appAccentPurple.opacity(0.4), radius: 8, x: 0, y: 4)
                                }
                            }
                            
                            // Favorite Button
                            Button(action: toggleFavorite) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.title3)
                                    .foregroundColor(isFavorite ? .appAccentPink : .white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.appCardBg)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isFavorite ? Color.appAccentPink.opacity(0.6) : Color.appCardBorder, lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Metadata Details
                        VStack(alignment: .leading, spacing: 8) {
                            if !movie.category.isEmpty {
                                HStack(alignment: .top) {
                                    Text("Thể loại:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(movie.category.joined(separator: " • "))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            
                            if !movie.actor.isEmpty {
                                HStack(alignment: .top) {
                                    Text("Diễn viên:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(movie.actor.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(2)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .glassCard(cornerRadius: 14)
                        
                        // Episodes List
                        if !movie.episodes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Danh Sách Tập")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(movie.episodes.count) tập")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], spacing: 10) {
                                    ForEach(movie.episodes) { ep in
                                        Button(action: {
                                            selectedEpisode = ep
                                            isPlaying = true
                                        }) {
                                            Text(ep.name)
                                                .font(.system(size: 13, weight: .semibold))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    selectedEpisode?.id == ep.id ?
                                                    LinearGradient(colors: [.appAccentBlue, .appAccentPurple], startPoint: .leading, endPoint: .trailing) :
                                                    LinearGradient(colors: [Color.appCardBg], startPoint: .leading, endPoint: .trailing)
                                                )
                                                .foregroundColor(selectedEpisode?.id == ep.id ? .white : .gray)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedEpisode?.id == ep.id ? Color.clear : Color.appCardBorder, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Description Card with strict boundary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nội Dung Phim")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(cleanDescription)
                                .font(.system(size: 14))
                                .lineSpacing(5)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .glassCard(cornerRadius: 14)
                        
                        // Related Movies Section
                        if !relatedMovies.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "film.stack.fill")
                                        .foregroundColor(.appAccentBlue)
                                    Text("Phim Tương Tự")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(relatedMovies) { rel in
                                            NavigationLink(destination: LazyView(MovieDetailView(movie: rel))) {
                                                MovieCard(movie: rel)
                                                    .frame(width: 135)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkFavoriteStatus()
            loadDetail()
            loadRelatedMovies()
        }
        .fullScreenCover(isPresented: $isPlaying) {
            if let ep = selectedEpisode ?? movie.episodes.first {
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
        isFavorite = FavoritesService.shared.isFavorite(movieID: movie.id)
    }
    
    private func toggleFavorite() {
        FavoritesService.shared.toggleFavorite(movie: movie)
        isFavorite = FavoritesService.shared.isFavorite(movieID: movie.id)
    }
    
    private func loadRelatedMovies() {
        Task {
            // Search by first category or actor or fetch source list
            let queryKey = movie.category.first ?? movie.actor.first
            var items: [UnifiedMovie] = []
            if let q = queryKey, !q.isEmpty {
                items = (try? await APIService.shared.searchMovies(query: q, source: movie.source)) ?? []
            }
            if items.isEmpty {
                items = (try? await APIService.shared.fetchMovies(source: movie.source, page: 1)) ?? []
            }
            let filtered = items.filter { $0.id != movie.id }
            await MainActor.run {
                self.relatedMovies = Array(filtered.prefix(10))
            }
        }
    }
}
