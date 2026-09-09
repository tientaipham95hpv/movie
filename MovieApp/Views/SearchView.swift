import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var selectedSource: MovieSource = .all
    @State private var searchResults: [UnifiedMovie] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 14) {
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
                    
                    if isSearching {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView().tint(.appAccentPurple).scaleEffect(1.2)
                            Text("Đang tìm kiếm phim...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
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
                            
                            Text("Tìm kiếm phim bộ, phim lẻ từ VSPHIM và AVDB")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(searchResults) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
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
    }
    
    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
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
