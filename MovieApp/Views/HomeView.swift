import SwiftUI

struct ResumePlayerView: View {
    let item: HistoryItem
    
    var body: some View {
        PlayerScreenView(
            episode: UnifiedEpisode(id: item.episodeID, name: item.episodeName, embedURL: item.embedURL),
            movieTitle: item.movieTitle
        )
    }
}

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
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 10) {
                    headerView
                    
                    SourcePicker(selectedSource: $selectedSource)
                        .onChange(of: selectedSource) { _ in
                            loadMovies(reset: true)
                        }
                    
                    if isLoading && movies.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.appAccentPurple)
                                .scaleEffect(1.2)
                            Text("Đang tải dữ liệu phim...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else if let error = errorMessage, movies.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 44))
                                .foregroundColor(.gray)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button(action: { loadMovies(reset: true) }) {
                                Text("Thử Lại")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(LinearGradient(colors: [.appAccentBlue, .appAccentPurple], startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(20)
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 18) {
                                if !historyService.historyList.isEmpty {
                                    continueWatchingSection
                                }
                                movieGridSection
                            }
                            .padding(.vertical, 8)
                        }
                        .refreshable {
                            await refreshMovies()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                historyService.loadHistory()
                if movies.isEmpty {
                    loadMovies(reset: true)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.appAccentBlue, .appAccentPink], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("PHIM HAY")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .appAccentBlue], startPoint: .leading, endPoint: .trailing)
                    )
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    private var continueWatchingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.appAccentPink)
                Text("Xem Tiếp")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(historyService.historyList) { item in
                        NavigationLink(destination: ResumePlayerView(item: item)) {
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack(alignment: .bottom) {
                                    CachedAsyncImage(urlString: item.posterURL) { img in
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle().fill(Color.appCardBg)
                                    }
                                    .frame(width: 145, height: 90)
                                    .cornerRadius(10)
                                    .clipped()
                                    
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        )
                                    
                                    GeometryReader { geo in
                                        VStack {
                                            Spacer()
                                            Rectangle()
                                                .fill(LinearGradient(colors: [.appAccentPink, .appAccentPurple], startPoint: .leading, endPoint: .trailing))
                                                .frame(width: geo.size.width * CGFloat(item.progress), height: 3)
                                        }
                                    }
                                }
                                .frame(width: 145, height: 90)
                                
                                Text(item.movieTitle)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                
                                Text(item.episodeName)
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 145)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var movieGridSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.appYellow)
                Text("Phim Mới Cập Nhật")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
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
            
            if isFetchingMore {
                HStack {
                    Spacer()
                    ProgressView().tint(.appAccentPurple)
                    Spacer()
                }
                .padding()
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
