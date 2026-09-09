import SwiftUI

struct HomeView: View {
    @State private var selectedSource: MovieSource = .all
    @State private var movies: [UnifiedMovie] = []
    @State private var page = 1
    @State private var isLoading = false
    @State private var isFetchingMore = false
    @State private var errorMessage: String?
    
    @ObservedObject var historyService = HistoryService.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Source Selector Bar
                SourcePicker(selectedSource: $selectedSource)
                    .padding(.vertical, 8)
                    .onChange(of: selectedSource) { _ in
                        loadMovies(reset: true)
                    }
                
                if isLoading && movies.isEmpty {
                    Spacer()
                    ProgressView("Đang tải danh sách phim...")
                    Spacer()
                } else if let error = errorMessage, movies.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Thử lại") {
                            loadMovies(reset: true)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        // MARK: - Continue Watching Section
                        if !historyService.historyList.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Xem Tiếp")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(historyService.historyList) { item in
                                            NavigationLink(destination: ResumePlayerView(item: item)) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    ZStack(alignment: .bottom) {
                                                        AsyncImage(url: URL(string: item.posterURL)) { phase in
                                                            if let img = phase.image {
                                                                img.resizable().aspectRatio(contentMode: .fill)
                                                            } else {
                                                                Rectangle().fill(Color.gray.opacity(0.3))
                                                            }
                                                        }
                                                        .frame(width: 140, height: 90)
                                                        .cornerRadius(8)
                                                        .clipped()
                                                        
                                                        // Play Icon Overlay
                                                        Image(systemName: "play.circle.fill")
                                                            .font(.title)
                                                            .foregroundColor(.white.opacity(0.9))
                                                        
                                                        // Progress Bar
                                                        GeometryReader { geo in
                                                            VStack {
                                                                Spacer()
                                                                Rectangle()
                                                                    .fill(Color.red)
                                                                    .frame(width: geo.size.width * CGFloat(item.progress), height: 4)
                                                            }
                                                        }
                                                    }
                                                    .frame(width: 140, height: 90)
                                                    
                                                    Text(item.movieTitle)
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .lineLimit(1)
                                                        .foregroundColor(.primary)
                                                    
                                                    Text(item.episodeName)
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                                .frame(width: 140)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // MARK: - Main Movie Grid
                        VStack(alignment: .leading) {
                            Text("Phim Mới Cập Nhật")
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(movies) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        MovieCard(movie: movie)
                                    }
                                    .onAppear {
                                        if movie == movies.last && !isFetchingMore {
                                            loadMoreMovies()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 4)
                        
                        if isFetchingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                    .refreshable {
                        await refreshMovies()
                    }
                }
            }
            .navigationTitle("Phim Hay iOS")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                historyService.loadHistory()
                if movies.isEmpty {
                    loadMovies(reset: true)
                }
            }
        }
    }
    
    private func loadMovies(reset: Bool = false) {
        if reset {
            page = 1
            isLoading = true
            errorMessage = nil
        }
        
        Task {
            do {
                let result = try await APIService.shared.fetchMovies(source: selectedSource, page: page)
                await MainActor.run {
                    if reset {
                        self.movies = result
                    } else {
                        self.movies.append(contentsOf: result)
                    }
                    self.isLoading = false
                    self.isFetchingMore = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.isFetchingMore = false
                }
            }
        }
    }
    
    private func loadMoreMovies() {
        guard !isFetchingMore else { return }
        isFetchingMore = true
        page += 1
        loadMovies(reset: false)
    }
    
    private func refreshMovies() async {
        page = 1
        if let result = try? await APIService.shared.fetchMovies(source: selectedSource, page: 1) {
            await MainActor.run {
                self.movies = result
            }
        }
    }
}

struct ResumePlayerView: View {
    let item: HistoryItem
    
    var body: some View {
        PlayerScreenView(
            episode: UnifiedEpisode(id: item.episodeID, name: item.episodeName, embedURL: item.embedURL),
            movieTitle: item.movieTitle
        )
    }
}
