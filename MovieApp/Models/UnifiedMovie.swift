import Foundation

// MARK: - Source Type
public enum MovieSource: String, Codable, CaseIterable, Identifiable {
    case all = "Tất Cả"
    case vsphim = "VSPHIM"
    case avdb = "AVDB"
    
    public var id: String { self.rawValue }
}

// MARK: - Unified Episode Model
public struct UnifiedEpisode: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let embedURL: String
    public let serverName: String
    
    public init(id: String = UUID().uuidString, name: String, embedURL: String, serverName: String = "VIP") {
        self.id = id
        self.name = name
        self.embedURL = embedURL
        self.serverName = serverName
    }
}

// MARK: - Unified Movie Model
public struct UnifiedMovie: Identifiable, Codable, Hashable {
    public let id: String
    public let source: MovieSource
    public let rawID: String
    public let title: String
    public let originalTitle: String
    public let slug: String
    public let posterURL: String
    public let thumbURL: String
    public var year: String
    public var quality: String
    public var category: [String]
    public var country: [String]
    public var actor: [String]
    public var description: String
    public var duration: String
    public var episodes: [UnifiedEpisode]
    
    public init(
        id: String? = nil,
        source: MovieSource,
        rawID: String,
        title: String,
        originalTitle: String = "",
        slug: String,
        posterURL: String,
        thumbURL: String,
        year: String = "",
        quality: String = "HD",
        category: [String] = [],
        country: [String] = [],
        actor: [String] = [],
        description: String = "",
        duration: String = "",
        episodes: [UnifiedEpisode] = []
    ) {
        self.id = id ?? "\(source.rawValue)_\(rawID)"
        self.source = source
        self.rawID = rawID
        self.title = title
        self.originalTitle = originalTitle
        self.slug = slug
        self.posterURL = UnifiedMovie.cleanImageURL(posterURL, baseURL: "https://nguon.vsphim.com")
        self.thumbURL = UnifiedMovie.cleanImageURL(thumbURL, baseURL: "https://nguon.vsphim.com")
        self.year = year
        self.quality = quality
        self.category = category
        self.country = country
        self.actor = actor
        self.description = description
        self.duration = duration
        self.episodes = episodes
    }
    
    // MARK: - Initializer from VSPhim
    public init(fromVSPhim item: VSPhimMovieItem) {
        self.id = "VSPHIM_\(item.id?.stringValue ?? UUID().uuidString)"
        self.source = .vsphim
        self.rawID = item.id?.stringValue ?? ""
        self.title = item.name ?? "Không có tiêu đề"
        self.originalTitle = item.origin_name ?? ""
        self.slug = item.slug ?? ""
        self.posterURL = UnifiedMovie.cleanImageURL(item.poster_url, baseURL: "https://nguon.vsphim.com")
        self.thumbURL = UnifiedMovie.cleanImageURL(item.thumb_url ?? item.poster_url, baseURL: "https://nguon.vsphim.com")
        self.year = item.year != nil ? String(item.year!) : ""
        self.quality = "HD"
        self.category = []
        self.country = []
        self.actor = []
        self.description = ""
        self.duration = ""
        self.episodes = []
    }
    
    // MARK: - Initializer from AVDB
    public init(fromAVDB item: AVDBMovieItem) {
        self.id = "AVDB_\(item.id?.stringValue ?? UUID().uuidString)"
        self.source = .avdb
        self.rawID = item.id?.stringValue ?? ""
        self.title = item.name ?? "Không có tiêu đề"
        self.originalTitle = item.origin_name ?? ""
        self.slug = item.slug ?? ""
        
        let rawPic = item.vod_pic ?? item.poster_url ?? item.vod_pic_thumb ?? item.thumb_url ?? item.vod_pic_slide
        let rawThumb = item.vod_pic_thumb ?? item.thumb_url ?? item.vod_pic ?? item.poster_url
        
        self.posterURL = UnifiedMovie.cleanImageURL(rawPic, baseURL: "https://avdbapi.com")
        self.thumbURL = UnifiedMovie.cleanImageURL(rawThumb ?? rawPic, baseURL: "https://avdbapi.com")
        self.year = item.year?.stringValue ?? ""
        self.quality = item.quality ?? "FHD"
        self.category = item.category?.arrayValue ?? []
        self.country = item.country?.arrayValue ?? []
        self.actor = item.actor?.arrayValue ?? []
        self.description = item.description ?? ""
        self.duration = item.vod_time ?? ""
        
        var eps: [UnifiedEpisode] = []
        if let serverData = item.episodes?.server_data {
            let serverName = item.episodes?.server_name ?? "VIP"
            for (key, ep) in serverData {
                let candidate = ep.link_m3u8 ?? ep.url ?? ep.link_embed
                if let link = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !link.isEmpty {
                    eps.append(UnifiedEpisode(name: key, embedURL: link, serverName: serverName))
                }
            }
        } else if let playUrl = item.vod_play_url, !playUrl.isEmpty {
            let serverNames = item.vod_play_from?.components(separatedBy: "$$$") ?? ["VIP"]
            let serverGroups = playUrl.components(separatedBy: "$$$")
            for (idx, groupStr) in serverGroups.enumerated() {
                let sName = idx < serverNames.count ? serverNames[idx] : "VIP"
                let epItems = groupStr.components(separatedBy: "#")
                for epStr in epItems {
                    let parts = epStr.components(separatedBy: "$")
                    if parts.count >= 2 {
                        let epName = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let epLink = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !epLink.isEmpty {
                            eps.append(UnifiedEpisode(name: epName.isEmpty ? "Full" : epName, embedURL: epLink, serverName: sName))
                        }
                    } else if parts.count == 1 && !parts[0].isEmpty {
                        eps.append(UnifiedEpisode(name: "Full", embedURL: parts[0], serverName: sName))
                    }
                }
            }
        }
        self.episodes = eps
    }
    
    // MARK: - Clean & Normalize Image URLs
    public static func cleanImageURL(_ rawURL: String?, baseURL: String) -> String {
        guard var url = rawURL?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty else { return "" }
        if url.hasPrefix("//") {
            return "https:" + url
        }
        if url.hasPrefix("/") {
            return baseURL + url
        }
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            return "https://" + url
        }
        if url.hasPrefix("http://") {
            url = url.replacingOccurrences(of: "http://", with: "https://")
        }
        return url
    }
}
