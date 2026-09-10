import Foundation

public class SearchHistoryService: ObservableObject {
    public static let shared = SearchHistoryService()
    private let key = "UserRecentSearches_V1"
    
    @Published public var recentQueries: [String] = []
    
    public init() {
        loadHistory()
    }
    
    public func addQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Skip saving if Incognito Mode is ON
        if SecurityService.shared.isIncognitoMode { return }
        
        var list = getHistory()
        list.removeAll(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        list.insert(trimmed, at: 0)
        
        if list.count > 10 {
            list = Array(list.prefix(10))
        }
        
        saveToStorage(list)
    }
    
    public func removeQuery(_ query: String) {
        var list = getHistory()
        list.removeAll(where: { $0.caseInsensitiveCompare(query) == .orderedSame })
        saveToStorage(list)
    }
    
    public func clearHistory() {
        UserDefaults.standard.removeObject(forKey: key)
        self.recentQueries = []
    }
    
    public func getHistory() -> [String] {
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    public func loadHistory() {
        self.recentQueries = getHistory()
    }
    
    private func saveToStorage(_ list: [String]) {
        UserDefaults.standard.set(list, forKey: key)
        DispatchQueue.main.async {
            self.recentQueries = list
        }
    }
}
