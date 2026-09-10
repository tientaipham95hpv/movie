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
    
    enum CodingKeys: String, CodingKey {
        case id, vod_id
        case name, vod_name
        case origin_name, vod_sub
        case slug, vod_en
        case movie_code, tag
        case category
        case vod_class, type_name
        case poster_url, thumb_url
        case vod_pic, vod_pic_thumb, vod_pic_slide
        case actor, vod_actor
        case director, vod_director
        case country, vod_area
        case year, vod_year
        case quality, vod_remarks
        case status
        case description, vod_content, content
        case vod_time, time
        case episodes
        case vod_play_from, vod_play_url
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = (try? container.decodeIfPresent(IntOrString.self, forKey: .id))
            ?? (try? container.decodeIfPresent(IntOrString.self, forKey: .vod_id))
        
        self.name = (try? container.decodeIfPresent(String.self, forKey: .name))
            ?? (try? container.decodeIfPresent(String.self, forKey: .vod_name))
        
        self.origin_name = (try? container.decodeIfPresent(String.self, forKey: .origin_name))
            ?? (try? container.decodeIfPresent(String.self, forKey: .vod_sub))
        
        self.slug = (try? container.decodeIfPresent(String.self, forKey: .slug))
            ?? (try? container.decodeIfPresent(String.self, forKey: .vod_en))
        
        self.movie_code = try? container.decodeIfPresent(String.self, forKey: .movie_code)
        self.tag = try? container.decodeIfPresent(String.self, forKey: .tag)
        
        self.category = (try? container.decodeIfPresent(StringOrArray.self, forKey: .category))
            ?? (try? container.decodeIfPresent(StringOrArray.self, forKey: .vod_class))
            ?? (try? container.decodeIfPresent(StringOrArray.self, forKey: .type_name))
        
        self.poster_url = try? container.decodeIfPresent(String.self, forKey: .poster_url)
        self.thumb_url = try? container.decodeIfPresent(String.self, forKey: .thumb_url)
        self.vod_pic = try? container.decodeIfPresent(String.self, forKey: .vod_pic)
        self.vod_pic_thumb = try? container.decodeIfPresent(String.self, forKey: .vod_pic_thumb)
        self.vod_pic_slide = try? container.decodeIfPresent(String.self, forKey: .vod_pic_slide)
        
        self.actor = (try? container.decodeIfPresent(StringOrArray.self, forKey: .actor))
            ?? (try? container.decodeIfPresent(StringOrArray.self, forKey: .vod_actor))
        
        self.director = (try? container.decodeIfPresent(StringOrArray.self, forKey: .director))
            ?? (try? container.decodeIfPresent(StringOrArray.self, forKey: .vod_director))
        
        self.country = (try? container.decodeIfPresent(StringOrArray.self, forKey: .country))
            ?? (try? container.decodeIfPresent(StringOrArray.self, forKey: .vod_area))
        
        self.year = (try? container.decodeIfPresent(IntOrString.self, forKey: .year))
            ?? (try? container.decodeIfPresent(IntOrString.self, forKey: .vod_year))
        
        self.quality = (try? container.decodeIfPresent(String.self, forKey: .quality))
            ?? (try? container.decodeIfPresent(String.self, forKey: .vod_remarks))
        
        self.status = try? container.decodeIfPresent(String.self, forKey: .status)
        
        self.description = (try? container.decodeIfPresent(String.self, forKey: .description))
            ?? (try? container.decodeIfPresent(String.self, forKey: .vod_content))
            ?? (try? container.decodeIfPresent(String.self, forKey: .content))
        
        self.vod_time = (try? container.decodeIfPresent(String.self, forKey: .vod_time))
            ?? (try? container.decodeIfPresent(String.self, forKey: .time))
        
        self.episodes = try? container.decodeIfPresent(AVDBEpisodesContainer.self, forKey: .episodes)
        self.vod_play_from = try? container.decodeIfPresent(String.self, forKey: .vod_play_from)
        self.vod_play_url = try? container.decodeIfPresent(String.self, forKey: .vod_play_url)
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

