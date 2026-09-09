import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var selectedSource: MovieSource = .all
    @State private var searchResults: [UnifiedMovie] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Nhập tên phim, diễn viên...", text: $query)
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
                .padding(10)
                .background(Color(UIColor.tertiarySystemFill))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Source Selector
                SourcePicker(selectedSource: $selectedSource)
                    .onChange(of: selectedSource) { _ in
                        if !query.isEmpty { performSearch() }
                    }
                
                if isSearching {
                    Spacer()
                    ProgressView("Đang tìm kiếm...")
                    Spacer()
                } else if searchResults.isEmpty && !query.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "film.stack")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Không tìm thấy kết quả nào cho '\(query)'")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue.opacity(0.7))
                        Text("Tìm Kiếm Phim Trực Tuyến")
                            .font(.headline)
                        Text("Hỗ trợ tìm kiếm từ VSPHIM và AVDB API")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(searchResults) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    MovieCard(movie: movie)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Tìm Kiếm")
            .navigationBarTitleDisplayMode(.inline)
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
