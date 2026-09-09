import Foundation

public enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Đường dẫn API không hợp lệ"
        case .networkError(let err): return "Lỗi kết nối mạng: \(err.localizedDescription)"
        case .decodingError(let err): return "Lỗi giải mã dữ liệu: \(err.localizedDescription)"
        case .serverError(let code): return "Lỗi máy chủ HTTP \(code)"
        }
    }
}

public class APIService: ObservableObject {
    public static let shared = APIService()
    
    private let session: URLSession
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    private func createRequest(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        return req
    }
    
    // MARK: - Fetch Movies List
    public func fetchMovies(source: MovieSource, page: Int = 1) async throws -> [UnifiedMovie] {
        switch source {
        case .vsphim:
            return try await fetchVSPhimList(page: page)
        case .avdb:
            return try await fetchAVDBList(page: page)
        case .all:
            async let vsMovies = (try? fetchVSPhimList(page: page)) ?? []
            async let avMovies = (try? fetchAVDBList(page: page)) ?? []
            let vs = await vsMovies
            let av = await avMovies
            
            // Interleave results smoothly
            var combined: [UnifiedMovie] = []
            let maxCount = max(vs.count, av.count)
            for i in 0..<maxCount {
                if i < vs.count { combined.append(vs[i]) }
                if i < av.count { combined.append(av[i]) }
            }
            return combined
        }
    }
    
    // MARK: - VSPhim List API
    private func fetchVSPhimList(page: Int) async throws -> [UnifiedMovie] {
        guard let url = URL(string: "https://nguon.vsphim.com/api/danh-sach/phim-moi-cap-nhat?page=\(page)") else {
            throw APIError.invalidURL
        }
        let req = createRequest(url: url)
        do {
            let (data, response) = try await session.data(for: req)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode != 200 {
                throw APIError.serverError(httpRes.statusCode)
            }
            let decoded = try JSONDecoder().decode(VSPhimListResponse.self, from: data)
            guard let items = decoded.items else { return [] }
            return items.map { UnifiedMovie(fromVSPhim: $0) }
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - AVDB List API
    private func fetchAVDBList(page: Int) async throws -> [UnifiedMovie] {
        guard let url = URL(string: "https://avdbapi.com/api.php/provide/vod/at/json?ac=list&pg=\(page)") else {
            throw APIError.invalidURL
        }
        let req = createRequest(url: url)
        do {
            let (data, response) = try await session.data(for: req)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode != 200 {
                throw APIError.serverError(httpRes.statusCode)
            }
            let decoded = try JSONDecoder().decode(AVDBListResponse.self, from: data)
            guard let items = decoded.list else { return [] }
            return items.map { UnifiedMovie(fromAVDB: $0) }
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Fetch Movie Detail
    public func fetchMovieDetail(movie: UnifiedMovie) async throws -> UnifiedMovie {
        var updated = movie
        if movie.source == .vsphim {
            guard let url = URL(string: "https://nguon.vsphim.com/api/phim/\(movie.slug)") else { return movie }
            let req = createRequest(url: url)
            let (data, _) = try await session.data(for: req)
            let decoded = try JSONDecoder().decode(VSPhimDetailResponse.self, from: data)
            if let m = decoded.movie {
                updated.description = m.content ?? ""
                updated.actor = m.actor ?? []
                updated.year = m.year != nil ? String(m.year!) : movie.year
                updated.quality = m.quality ?? movie.quality
                updated.category = m.category?.compactMap { $0.name } ?? []
                updated.country = m.country?.compactMap { $0.name } ?? []
                updated.duration = m.time ?? ""
            }
            
            var eps: [UnifiedEpisode] = []
            if let serverGroups = decoded.episodes {
                for group in serverGroups {
                    let sName = group.server_name ?? "VIP"
                    if let listData = group.server_data {
                        for item in listData {
                            if let embed = item.link_embed, !embed.isEmpty {
                                eps.append(UnifiedEpisode(name: item.name ?? "Tập Full", embedURL: embed, serverName: sName))
                            }
                        }
                    }
                }
            }
            updated.episodes = eps
        } else if movie.source == .avdb {
            guard let url = URL(string: "https://avdbapi.com/api.php/provide/vod/at/json?ac=detail&ids=\(movie.rawID)") else { return movie }
            let req = createRequest(url: url)
            let (data, _) = try await session.data(for: req)
            let decoded = try JSONDecoder().decode(AVDBListResponse.self, from: data)
            if let item = decoded.list?.first {
                updated = UnifiedMovie(fromAVDB: item)
            }
        }
        return updated
    }
    
    // MARK: - Search Movies
    public func searchMovies(query: String, source: MovieSource = .all, page: Int = 1) async throws -> [UnifiedMovie] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        switch source {
        case .vsphim:
            return try await searchVSPhim(query: encodedQuery, page: page)
        case .avdb:
            return try await searchAVDB(query: encodedQuery, page: page)
        case .all:
            async let vs = (try? searchVSPhim(query: encodedQuery, page: page)) ?? []
            async let av = (try? searchAVDB(query: encodedQuery, page: page)) ?? []
            let vsRes = await vs
            let avRes = await av
            return vsRes + avRes
        }
    }
    
    private func searchVSPhim(query: String, page: Int) async throws -> [UnifiedMovie] {
        guard let url = URL(string: "https://nguon.vsphim.com/api/tim-kiem?keyword=\(query)&page=\(page)") else { return [] }
        let req = createRequest(url: url)
        let (data, _) = try await session.data(for: req)
        let decoded = try JSONDecoder().decode(VSPhimListResponse.self, from: data)
        return decoded.items?.map { UnifiedMovie(fromVSPhim: $0) } ?? []
    }
    
    private func searchAVDB(query: String, page: Int) async throws -> [UnifiedMovie] {
        guard let url = URL(string: "https://avdbapi.com/api.php/provide/vod/at/json?ac=detail&wd=\(query)&pg=\(page)") else { return [] }
        let req = createRequest(url: url)
        let (data, _) = try await session.data(for: req)
        let decoded = try JSONDecoder().decode(AVDBListResponse.self, from: data)
        return decoded.list?.map { UnifiedMovie(fromAVDB: $0) } ?? []
    }
}
