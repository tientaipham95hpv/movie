import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var selectedSource: MovieSource = .all
    @State private var searchResults: [UnifiedMovie] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    @ObservedObject var searchHistory = SearchHistoryService.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Glass Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                            .foregroundColor(.appAccentBlue)
                        
                        TextField("Nhập tên phim, diễn viên...", text: $query)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !query.isEmpty {
                            Button(action: { query = ""; searchResults = [] }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal)
                    
                    // Source Picker
                    SourcePicker(selectedSource: $selectedSource)
                        .onChange(of: selectedSource) { _ in
                            if !query.isEmpty { performSearch() }
                        }
                    
                    // Quick Filter Chips (Categories, Actors, Years & Countries)
                    VStack(alignment: .leading, spacing: 6) {
                        // Category Chips Row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["Vietsub", "Uncensored", "Chinese AV", "Hentai", "Hành Động", "Tình Cảm", "Học Đường", "Văn Phòng", "Y Tá", "Gia Đình", "Hài Hước"], id: \.self) { cat in
                                    filterButton(title: cat, isSelected: query == cat, color: .appAccentBlue)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Top Actors Row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["Miu Shiramine", "Yua Mikami", "Eimi Fukada", "Yui Hatano", "Riri Nanatsumori", "Karen Kaede", "Saika Kawakita", "Remu Suzumori"], id: \.self) { actor in
                                    Button(action: {
                                        query = actor
                                        performSearch()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 9))
                                                .foregroundColor(.appYellow)
                                            Text(actor)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(query == actor ? Color.appAccentPurple : Color.appCardBg)
                                        .foregroundColor(query == actor ? .white : .gray)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(query == actor ? Color.clear : Color.appCardBorder, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Year & Country Row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["2024", "2023", "2022", "2021", "Nhật Bản", "Trung Quốc", "Âu Mỹ", "Hàn Quốc"], id: \.self) { item in
                                    filterButton(title: item, isSelected: query == item, color: .appAccentPink)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    if isSearching {
                        // Skeleton Shimmer Loading Grid
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(0..<6, id: \.self) { _ in
                                    SkeletonMovieCard()
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }
                    } else if searchResults.isEmpty && !query.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("Không tìm thấy phim '\(query)'")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Thử tìm kiếm với từ khóa khác hoặc chuyển nguồn API")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else if searchResults.isEmpty {
                        // Empty query state with Recent Searches if available
                        if !searchHistory.recentQueries.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.appAccentBlue)
                                    Text("Tìm Kiếm Gần Đây")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button("Xóa") {
                                        searchHistory.clearHistory()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(searchHistory.recentQueries, id: \.self) { recent in
                                            Button(action: {
                                                query = recent
                                                performSearch()
                                            }) {
                                                HStack(spacing: 4) {
                                                    Text(recent)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white.opacity(0.9))
                                                    Button(action: { searchHistory.removeQuery(recent) }) {
                                                        Image(systemName: "xmark")
                                                            .font(.system(size: 9))
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.appCardBg)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.appCardBorder, lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.appAccentBlue.opacity(0.2), .appAccentPurple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 90, height: 90)
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 36))
                                    .foregroundColor(.appAccentBlue)
                            }
                            
                            Text("Tìm Kiếm Phim Trực Tuyến")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Tìm kiếm phim bộ, phim lẻ, diễn viên từ VSPHIM và AVDB")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(searchResults) { movie in
                                    NavigationLink(destination: LazyView(MovieDetailView(movie: movie))) {
                                        MovieCard(movie: movie)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
    
    private func filterButton(title: String, isSelected: Bool, color: Color) -> some View {
        Button(action: {
            query = title
            performSearch()
        }) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.appCardBg)
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.appCardBorder, lineWidth: 1)
                )
        }
    }
    
    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        searchHistory.addQuery(query)
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await APIService.shared.searchMovies(query: query, source: selectedSource)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSearching = false
                }
            }
        }
    }
}
