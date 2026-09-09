import SwiftUI

struct MovieDetailView: View {
    let initialMovie: UnifiedMovie
    @State private var movie: UnifiedMovie
    @State private var isLoading = true
    @State private var selectedEpisode: UnifiedEpisode?
    @State private var isFavorite = false
    @State private var isPlaying = false
    @State private var isDownloading = false
    
    @ObservedObject var downloadManager = DownloadManager.shared
    
    init(movie: UnifiedMovie) {
        self.initialMovie = movie
        self._movie = State(initialValue: movie)
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero Poster Backdrop Banner
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: movie.posterURL.isEmpty ? movie.thumbURL : movie.posterURL)) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Rectangle().fill(Color.appCardBg)
                            }
                        }
                        .frame(height: 320)
                        .clipped()
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
                                        .font(.system(size: 10, weight: .black))
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
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            if !movie.originalTitle.isEmpty {
                                Text(movie.originalTitle)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
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
                            
                            // Download Button
                            if let ep = selectedEpisode ?? movie.episodes.first {
                                Button(action: {
                                    Task {
                                        if let stream = await HLSExtractorService.shared.extractStreamURL(from: ep.embedURL) {
                                            downloadManager.startDownload(movie: movie, episode: ep, streamURL: stream)
                                            isDownloading = true
                                        }
                                    }
                                }) {
                                    Image(systemName: isDownloading ? "arrow.down.circle.fill" : "arrow.down.circle")
                                        .font(.title3)
                                        .foregroundColor(isDownloading ? .appAccentBlue : .white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.appCardBg)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.appCardBorder, lineWidth: 1)
                                        )
                                }
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
                        
                        // Description
                        if !movie.description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nội Dung Phim")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(movie.description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                                    .font(.system(size: 14))
                                    .lineSpacing(4)
                                    .foregroundColor(.gray)
                            }
                            .padding(14)
                            .glassCard(cornerRadius: 14)
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
        }
        .fullScreenCover(isPresented: $isPlaying) {
            if let ep = selectedEpisode ?? movie.episodes.first {
                NativePlayerContainerView(movie: movie, episode: ep)
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
