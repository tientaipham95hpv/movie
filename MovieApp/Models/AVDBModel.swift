import Foundation

// MARK: - String Or Array Codable Helper
public enum StringOrArray: Codable {
    case string(String)
    case array([String])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arr = try? container.decode([String].self) {
            self = .array(arr)
            return
        }
        if let str = try? container.decode(String.self) {
            self = .string(str)
            return
        }
        self = .array([])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .array(let a): try container.encode(a)
        }
    }
    
    public var arrayValue: [String] {
        switch self {
        case .string(let s):
            return s.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        case .array(let a):
            return a
        }
    }
}

// MARK: - Dynamic Coding Key Helper
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    static func key(_ string: String) -> DynamicCodingKey {
        return DynamicCodingKey(stringValue: string)!
    }
}

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
    public let category: StringOrArray?
    public let poster_url: String?
    public let thumb_url: String?
    public let vod_pic: String?
    public let vod_pic_thumb: String?
    public let vod_pic_slide: String?
    public let actor: StringOrArray?
    public let director: StringOrArray?
    public let country: StringOrArray?
    public let year: IntOrString?
    public let quality: String?
    public let status: String?
    public let description: String?
    public let vod_time: String?
    public let episodes: AVDBEpisodesContainer?
    public let vod_play_from: String?
    public let vod_play_url: String?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        func decodeString(_ keys: [String]) -> String? {
            for k in keys {
                if let val = try? container.decodeIfPresent(String.self, forKey: DynamicCodingKey.key(k)), !val.isEmpty {
                    return val
                }
            }
            return nil
        }
        
        func decodeIntOrString(_ keys: [String]) -> IntOrString? {
            for k in keys {
                if let val = try? container.decodeIfPresent(IntOrString.self, forKey: DynamicCodingKey.key(k)) {
                    return val
                }
            }
            return nil
        }
        
        func decodeStringOrArray(_ keys: [String]) -> StringOrArray? {
            for k in keys {
                if let val = try? container.decodeIfPresent(StringOrArray.self, forKey: DynamicCodingKey.key(k)) {
                    return val
                }
            }
            return nil
        }
        
        self.id = decodeIntOrString(["id", "vod_id"])
        self.name = decodeString(["name", "vod_name"])
        self.origin_name = decodeString(["origin_name", "vod_sub"])
        self.slug = decodeString(["slug", "vod_en"])
        self.movie_code = decodeString(["movie_code"])
        self.tag = decodeString(["tag"])
        self.category = decodeStringOrArray(["category", "vod_class", "type_name"])
        self.poster_url = decodeString(["poster_url"])
        self.thumb_url = decodeString(["thumb_url"])
        self.vod_pic = decodeString(["vod_pic"])
        self.vod_pic_thumb = decodeString(["vod_pic_thumb"])
        self.vod_pic_slide = decodeString(["vod_pic_slide"])
        self.actor = decodeStringOrArray(["actor", "vod_actor"])
        self.director = decodeStringOrArray(["director", "vod_director"])
        self.country = decodeStringOrArray(["country", "vod_area"])
        self.year = decodeIntOrString(["year", "vod_year"])
        self.quality = decodeString(["quality", "vod_remarks"])
        self.status = decodeString(["status"])
        self.description = decodeString(["description", "vod_content", "content"])
        self.vod_time = decodeString(["vod_time", "time"])
        self.episodes = try? container.decodeIfPresent(AVDBEpisodesContainer.self, forKey: DynamicCodingKey.key("episodes"))
        self.vod_play_from = decodeString(["vod_play_from"])
        self.vod_play_url = decodeString(["vod_play_url"])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        try container.encodeIfPresent(id, forKey: DynamicCodingKey.key("id"))
        try container.encodeIfPresent(name, forKey: DynamicCodingKey.key("name"))
        try container.encodeIfPresent(origin_name, forKey: DynamicCodingKey.key("origin_name"))
        try container.encodeIfPresent(slug, forKey: DynamicCodingKey.key("slug"))
        try container.encodeIfPresent(movie_code, forKey: DynamicCodingKey.key("movie_code"))
        try container.encodeIfPresent(tag, forKey: DynamicCodingKey.key("tag"))
        try container.encodeIfPresent(category, forKey: DynamicCodingKey.key("category"))
        try container.encodeIfPresent(poster_url, forKey: DynamicCodingKey.key("poster_url"))
        try container.encodeIfPresent(thumb_url, forKey: DynamicCodingKey.key("thumb_url"))
        try container.encodeIfPresent(vod_pic, forKey: DynamicCodingKey.key("vod_pic"))
        try container.encodeIfPresent(vod_pic_thumb, forKey: DynamicCodingKey.key("vod_pic_thumb"))
        try container.encodeIfPresent(vod_pic_slide, forKey: DynamicCodingKey.key("vod_pic_slide"))
        try container.encodeIfPresent(actor, forKey: DynamicCodingKey.key("actor"))
        try container.encodeIfPresent(director, forKey: DynamicCodingKey.key("director"))
        try container.encodeIfPresent(country, forKey: DynamicCodingKey.key("country"))
        try container.encodeIfPresent(year, forKey: DynamicCodingKey.key("year"))
        try container.encodeIfPresent(quality, forKey: DynamicCodingKey.key("quality"))
        try container.encodeIfPresent(status, forKey: DynamicCodingKey.key("status"))
        try container.encodeIfPresent(description, forKey: DynamicCodingKey.key("description"))
        try container.encodeIfPresent(vod_time, forKey: DynamicCodingKey.key("vod_time"))
        try container.encodeIfPresent(episodes, forKey: DynamicCodingKey.key("episodes"))
        try container.encodeIfPresent(vod_play_from, forKey: DynamicCodingKey.key("vod_play_from"))
        try container.encodeIfPresent(vod_play_url, forKey: DynamicCodingKey.key("vod_play_url"))
    }
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

