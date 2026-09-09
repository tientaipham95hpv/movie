import Foundation

// MARK: - VSPHIM Models
public struct VSPhimListResponse: Codable {
    public let status: Bool
    public let items: [VSPhimMovieItem]?
    public let pathImage: String?
    public let pagination: VSPhimPagination?
}

public struct VSPhimPagination: Codable {
    public let totalItems: Int?
    public let totalItemsPerPage: Int?
    public let currentPage: Int?
    public let totalPages: Int?
}

public struct VSPhimMovieItem: Codable {
    public let id: IntOrString?
    public let name: String?
    public let origin_name: String?
    public let slug: String?
    public let poster_url: String?
    public let thumb_url: String?
    public let year: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, origin_name, slug, poster_url, thumb_url, year
    }
}

public struct VSPhimDetailResponse: Codable {
    public let status: Bool
    public let msg: String?
    public let movie: VSPhimMovieDetail?
    public let episodes: [VSPhimServerGroup]?
}

public struct VSPhimMovieDetail: Codable {
    public let id: IntOrString?
    public let name: String?
    public let origin_name: String?
    public let slug: String?
    public let content: String?
    public let type: String?
    public let status: String?
    public let poster_url: String?
    public let thumb_url: String?
    public let time: String?
    public let episode_current: String?
    public let episode_total: String?
    public let quality: String?
    public let lang: String?
    public let year: Int?
    public let view: Int?
    public let actor: [String]?
    public let director: [String]?
    public let category: [VSPhimCategory]?
    public let country: [VSPhimCountry]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, origin_name, slug, content, type, status, poster_url, thumb_url, time, episode_current, episode_total, quality, lang, year, view, actor, director, category, country
    }
}

public struct VSPhimCategory: Codable, Identifiable {
    public let idValue: IntOrString?
    public let name: String?
    public let slug: String?
    
    public var id: String {
        return idValue?.stringValue ?? slug ?? UUID().uuidString
    }
    
    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case name, slug
    }
}

public struct VSPhimCountry: Codable, Identifiable {
    public let idValue: IntOrString?
    public let name: String?
    public let slug: String?
    
    public var id: String {
        return idValue?.stringValue ?? slug ?? UUID().uuidString
    }
    
    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case name, slug
    }
}

public struct VSPhimServerGroup: Codable {
    public let server_name: String?
    public let server_data: [VSPhimEpisodeData]?
}

public struct VSPhimEpisodeData: Codable {
    public let name: String?
    public let slug: String?
    public let filename: String?
    public let link_embed: String?
}

// Flexible Helper for String or Int JSON keys
public enum IntOrString: Codable {
    case int(Int)
    case string(String)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .int(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(IntOrString.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String"))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        }
    }
    
    public var stringValue: String {
        switch self {
        case .int(let val): return String(val)
        case .string(let val): return val
        }
    }
}
