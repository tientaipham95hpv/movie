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

public class DownloadManager: NSObject, ObservableObject {
    public static let shared = DownloadManager()
    private let key = "UserDownloadedEpisodes_V1"
    
    @Published public var downloads: [DownloadedEpisode] = []
    @Published public var currentDownloadProgress: Float = 0.0
    @Published public var isDownloading = false
    @Published public var statusMessage: String = ""
    @Published public var currentDownloadingEpisodeID: String? = nil
    
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
    
    override public init() {
        super.init()
        loadDownloads()
    }
    
    public func isEpisodeDownloaded(movieID: String, episodeID: String) -> Bool {
        let targetID = "\(movieID)_\(episodeID)"
        return downloads.contains(where: { $0.id == targetID })
    }
    
    public func startDownload(movie: UnifiedMovie, episode: UnifiedEpisode, streamURL: String) {
        let epID = "\(movie.id)_\(episode.id)"
        self.currentDownloadingEpisodeID = epID
        self.isDownloading = true
        self.currentDownloadProgress = 0.05
        self.statusMessage = "Đang kết nối luồng video..."
        
        Task {
            let extracted = await HLSExtractorService.shared.extractStreamURL(from: streamURL) ?? streamURL
            guard let url = URL(string: extracted) else {
                await MainActor.run {
                    self.isDownloading = false
                    self.statusMessage = "Đường dẫn không hợp lệ"
                    self.currentDownloadingEpisodeID = nil
                }
                return
            }
            
            if extracted.contains(".m3u8") {
                await downloadHLSStream(movie: movie, episode: episode, m3u8URL: url)
            } else {
                await downloadDirectFile(movie: movie, episode: episode, url: url)
            }
        }
    }
    
    public func cancelDownload() {
        isDownloading = false
        currentDownloadProgress = 0.0
        statusMessage = "Đã hủy tải xuống"
        currentDownloadingEpisodeID = nil
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
    
    // MARK: - HLS (.m3u8) Downloader
    private func downloadHLSStream(movie: UnifiedMovie, episode: UnifiedEpisode, m3u8URL: URL) async {
        await MainActor.run {
            self.statusMessage = "Đang đọc danh sách phân đoạn m3u8..."
            self.currentDownloadProgress = 0.1
        }
        
        var request = URLRequest(url: m3u8URL)
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let playlistText = String(data: data, encoding: .utf8) else {
            await MainActor.run {
                self.isDownloading = false
                self.statusMessage = "Không thể tải file chỉ mục m3u8"
                self.currentDownloadingEpisodeID = nil
            }
            return
        }
        
        var targetPlaylistURL = m3u8URL
        var activePlaylistText = playlistText
        
        // Handle Master Playlist
        if playlistText.contains("#EXT-X-STREAM-INF") {
            let lines = playlistText.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                    if let childURL = URL(string: trimmed, relativeTo: m3u8URL)?.absoluteURL {
                        targetPlaylistURL = childURL
                        var childReq = URLRequest(url: childURL)
                        childReq.addValue(userAgent, forHTTPHeaderField: "User-Agent")
                        if let (childData, _) = try? await URLSession.shared.data(for: childReq),
                           let childText = String(data: childData, encoding: .utf8) {
                            activePlaylistText = childText
                        }
                    }
                    break
                }
            }
        }
        
        // Parse Segment URLs
        let lines = activePlaylistText.components(separatedBy: .newlines)
        var segmentURLs: [URL] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                if let segURL = URL(string: trimmed, relativeTo: targetPlaylistURL)?.absoluteURL {
                    segmentURLs.append(segURL)
                }
            }
        }
        
        guard !segmentURLs.isEmpty else {
            await MainActor.run {
                self.isDownloading = false
                self.statusMessage = "Không tìm thấy phân đoạn video m3u8"
                self.currentDownloadingEpisodeID = nil
            }
            return
        }
        
        // Output Destination File
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "\(movie.id)_\(episode.id).ts"
        let destURL = docs.appendingPathComponent(filename)
        
        try? FileManager.default.removeItem(at: destURL)
        FileManager.default.createFile(atPath: destURL.path, contents: nil, attributes: nil)
        
        guard let fileHandle = try? FileHandle(forWritingTo: destURL) else {
            await MainActor.run {
                self.isDownloading = false
                self.statusMessage = "Lỗi tạo file lưu trữ"
                self.currentDownloadingEpisodeID = nil
            }
            return
        }
        defer { try? fileHandle.close() }
        
        let totalCount = segmentURLs.count
        var downloadedCount = 0
        
        for segURL in segmentURLs {
            if !self.isDownloading { break }
            
            var segReq = URLRequest(url: segURL)
            segReq.addValue(userAgent, forHTTPHeaderField: "User-Agent")
            
            var fetchedData: Data? = nil
            for _ in 0..<3 {
                if let (d, res) = try? await URLSession.shared.data(for: segReq),
                   let httpRes = res as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
                    fetchedData = d
                    break
                }
            }
            
            if let segData = fetchedData {
                fileHandle.write(segData)
                downloadedCount += 1
                
                let progress = Float(downloadedCount) / Float(totalCount)
                await MainActor.run {
                    self.currentDownloadProgress = progress
                    self.statusMessage = "Đã tải \(downloadedCount)/\(totalCount) phân đoạn (\(Int(progress * 100))%)"
                }
            }
        }
        
        if downloadedCount > 0 {
            let attr = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
            let size = attr[.size] as? Int64 ?? 0
            
            let downloaded = DownloadedEpisode(
                id: "\(movie.id)_\(episode.id)",
                movieID: movie.id,
                movieTitle: movie.title,
                episodeName: episode.name,
                posterURL: movie.posterURL.isEmpty ? movie.thumbURL : movie.posterURL,
                localFilePath: destURL.path,
                fileSize: size,
                downloadDate: Date()
            )
            
            var list = getDownloads()
            list.removeAll(where: { $0.id == downloaded.id })
            list.insert(downloaded, at: 0)
            saveToStorage(list)
        }
        
        await MainActor.run {
            self.isDownloading = false
            self.currentDownloadProgress = downloadedCount > 0 ? 1.0 : 0.0
            self.statusMessage = downloadedCount > 0 ? "Tải xuống thành công!" : "Lỗi tải video"
            self.currentDownloadingEpisodeID = nil
        }
    }
    
    // MARK: - Direct File (.mp4) Downloader
    private func downloadDirectFile(movie: UnifiedMovie, episode: UnifiedEpisode, url: URL) async {
        await MainActor.run {
            self.statusMessage = "Đang tải tệp video trực tiếp..."
            self.currentDownloadProgress = 0.2
        }
        
        var request = URLRequest(url: url)
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            await MainActor.run {
                self.isDownloading = false
                self.statusMessage = "Lỗi máy chủ khi tải tệp"
                self.currentDownloadingEpisodeID = nil
            }
            return
        }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "\(movie.id)_\(episode.id).mp4"
        let destURL = docs.appendingPathComponent(filename)
        
        try? FileManager.default.removeItem(at: destURL)
        
        do {
            try data.write(to: destURL)
            let size = Int64(data.count)
            
            let downloaded = DownloadedEpisode(
                id: "\(movie.id)_\(episode.id)",
                movieID: movie.id,
                movieTitle: movie.title,
                episodeName: episode.name,
                posterURL: movie.posterURL.isEmpty ? movie.thumbURL : movie.posterURL,
                localFilePath: destURL.path,
                fileSize: size,
                downloadDate: Date()
            )
            
            var list = getDownloads()
            list.removeAll(where: { $0.id == downloaded.id })
            list.insert(downloaded, at: 0)
            saveToStorage(list)
            
            await MainActor.run {
                self.isDownloading = false
                self.currentDownloadProgress = 1.0
                self.statusMessage = "Tải xuống thành công!"
                self.currentDownloadingEpisodeID = nil
            }
        } catch {
            await MainActor.run {
                self.isDownloading = false
                self.statusMessage = "Lỗi ghi tệp"
                self.currentDownloadingEpisodeID = nil
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
