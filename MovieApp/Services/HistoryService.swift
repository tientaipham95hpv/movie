import Foundation

public struct HistoryItem: Codable, Identifiable {
    public let id: String
    public let movieID: String
    public let movieTitle: String
    public let episodeID: String
    public let episodeName: String
    public let posterURL: String
    public let embedURL: String
    public let source: String
    public var currentTime: Double
    public var duration: Double
    public var lastWatchedDate: Date
    
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1.0)
    }
}

public class HistoryService: ObservableObject {
    public static let shared = HistoryService()
    private let key = "UserWatchingHistory_V1"
    
    @Published public var historyList: [HistoryItem] = []
    
    public init() {
        loadHistory()
    }
    
    public func saveProgress(
        movie: UnifiedMovie,
        episode: UnifiedEpisode,
        currentTime: Double,
        duration: Double
    ) {
        guard duration > 0 else { return }
        
        var list = getHistoryList()
        let itemID = "\(movie.id)_\(episode.id)"
        
        if let idx = list.firstIndex(where: { $0.id == itemID }) {
            list[idx].currentTime = currentTime
            list[idx].duration = duration
            list[idx].lastWatchedDate = Date()
        } else {
            let newItem = HistoryItem(
                id: itemID,
                movieID: movie.id,
                movieTitle: movie.title,
                episodeID: episode.id,
                episodeName: episode.name,
                posterURL: movie.posterURL.isEmpty ? movie.thumbURL : movie.posterURL,
                embedURL: episode.embedURL,
                source: movie.source.rawValue,
                currentTime: currentTime,
                duration: duration,
                lastWatchedDate: Date()
            )
            list.insert(newItem, at: 0)
        }
        
        // Keep max 50 items
        if list.count > 50 {
            list = Array(list.prefix(50))
        }
        
        saveToStorage(list)
    }
    
    public func getHistoryList() -> [HistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return []
        }
        return list.sorted(by: { $0.lastWatchedDate > $1.lastWatchedDate })
    }
    
    public func loadHistory() {
        self.historyList = getHistoryList()
    }
    
    public func clearHistory() {
        UserDefaults.standard.removeObject(forKey: key)
        self.historyList = []
    }
    
    private func saveToStorage(_ list: [HistoryItem]) {
        if let encoded = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(encoded, forKey: key)
            DispatchQueue.main.async {
                self.historyList = list
            }
        }
    }
}
