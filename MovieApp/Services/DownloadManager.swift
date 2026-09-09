import Foundation

public struct DownloadedEpisode: Codable, Identifiable {
    public let id: String
    public let movieID: String
    public let movieTitle: String
    public let episodeName: String
    public let posterURL: String
    public let localFilePath: String
    public let fileSize: Int64
    public let downloadDate: Date
    
    public var formattedSize: String {
        let mb = Double(fileSize) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
}

public class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = DownloadManager()
    private let key = "UserDownloadedEpisodes_V1"
    
    @Published public var downloads: [DownloadedEpisode] = []
    @Published public var currentDownloadProgress: Float = 0.0
    @Published public var isDownloading = false
    
    private var session: URLSession!
    private var downloadTask: URLSessionDownloadTask?
    private var pendingEpisode: (movie: UnifiedMovie, episode: UnifiedEpisode)?
    
    override public init() {
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        loadDownloads()
    }
    
    public func startDownload(movie: UnifiedMovie, episode: UnifiedEpisode, streamURL: String) {
        guard let url = URL(string: streamURL) else { return }
        
        self.pendingEpisode = (movie, episode)
        self.isDownloading = true
        self.currentDownloadProgress = 0.0
        
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    public func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        currentDownloadProgress = 0.0
    }
    
    public func deleteDownload(id: String) {
        var list = getDownloads()
        if let idx = list.firstIndex(where: { $0.id == id }) {
            let item = list[idx]
            let fileURL = URL(fileURLWithPath: item.localFilePath)
            try? FileManager.default.removeItem(at: fileURL)
            list.remove(at: idx)
            saveToStorage(list)
        }
    }
    
    public func getDownloads() -> [DownloadedEpisode] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([DownloadedEpisode].self, from: data) else {
            return []
        }
        return list
    }
    
    public func loadDownloads() {
        self.downloads = getDownloads()
    }
    
    // MARK: - URLSessionDownloadDelegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let pending = pendingEpisode else { return }
        
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "\(pending.movie.id)_\(pending.episode.id).mp4"
        let destURL = docs.appendingPathComponent(filename)
        
        try? fileManager.removeItem(at: destURL)
        do {
            try fileManager.moveItem(at: location, to: destURL)
            let attr = try fileManager.attributesOfItem(atPath: destURL.path)
            let size = attr[.size] as? Int64 ?? 0
            
            let downloaded = DownloadedEpisode(
                id: "\(pending.movie.id)_\(pending.episode.id)",
                movieID: pending.movie.id,
                movieTitle: pending.movie.title,
                episodeName: pending.episode.name,
                posterURL: pending.movie.posterURL.isEmpty ? pending.movie.thumbURL : pending.movie.posterURL,
                localFilePath: destURL.path,
                fileSize: size,
                downloadDate: Date()
            )
            
            var list = getDownloads()
            list.insert(downloaded, at: 0)
            saveToStorage(list)
        } catch {
            print("Failed to save downloaded file: \(error)")
        }
        
        DispatchQueue.main.async {
            self.isDownloading = false
            self.currentDownloadProgress = 1.0
            self.pendingEpisode = nil
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let prog = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                self.currentDownloadProgress = prog
            }
        }
    }
    
    private func saveToStorage(_ list: [DownloadedEpisode]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
            DispatchQueue.main.async {
                self.downloads = list
            }
        }
    }
}
