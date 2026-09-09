import Foundation

// MARK: - AVDB API Models
public struct AVDBListResponse: Codable {
    public let code: Int?
    public let msg: String?
    public let page: IntOrString?
    public let pagecount: IntOrString?
    public let limit: String?
    public let total: IntOrString?
    public let list: [AVDBMovieItem]?
}

public struct AVDBMovieItem: Codable {
    public let id: IntOrString?
    public let name: String?
    public let origin_name: String?
    public let slug: String?
    public let movie_code: String?
    public let tag: String?
    public let category: [String]?
    public let poster_url: String?
    public let thumb_url: String?
    public let actor: [String]?
    public let director: [String]?
    public let country: [String]?
    public let year: String?
    public let quality: String?
    public let status: String?
    public let description: String?
    public let vod_time: String?
    public let episodes: AVDBEpisodesContainer?
}

public struct AVDBEpisodesContainer: Codable {
    public let server_name: String?
    public let server_data: [String: AVDBEpisodeDetail]?
    
    enum CodingKeys: String, CodingKey {
        case server_name
        case server_data
    }
}

public struct AVDBEpisodeDetail: Codable {
    public let slug: String?
    public let link_embed: String?
}
