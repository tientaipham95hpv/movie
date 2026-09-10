import Foundation

public class FavoritesService: ObservableObject {
    public static let shared = FavoritesService()
    
    @Published public var favorites: [UnifiedMovie] = []
    private let storageKey = "SavedFavoriteMovies_V1"
    
    public init() {
        loadFavorites()
    }
    
    public func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([UnifiedMovie].self, from: data) else {
            self.favorites = []
            return
        }
        self.favorites = list
    }
    
    public func isFavorite(movieID: String) -> Bool {
        return favorites.contains(where: { $0.id == movieID })
    }
    
    public func toggleFavorite(movie: UnifiedMovie) {
        if let idx = favorites.firstIndex(where: { $0.id == movie.id }) {
            favorites.remove(at: idx)
        } else {
            favorites.insert(movie, at: 0)
        }
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
