import Foundation

public class HLSExtractorService {
    public static let shared = HLSExtractorService()
    
    private let session: URLSession
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }
    
    /// Extract direct .m3u8 or .mp4 stream URL from an embed webpage URL
    public func extractStreamURL(from embedURL: String) async -> String? {
        guard let url = URL(string: embedURL) else { return nil }
        
        // If it already ends with .m3u8 or .mp4
        if embedURL.contains(".m3u8") || embedURL.contains(".mp4") {
            return embedURL
        }
        
        var req = URLRequest(url: url)
        req.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        do {
            let (data, _) = try await session.data(for: req)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            // Regex patterns for HLS .m3u8 / .mp4 links in player scripts
            let patterns = [
                #"https?://[^"'\s\\]+\.m3u8[^"'\s\\]*"#,
                #"file\s*:\s*["'](https?://[^"']+\.m3u8[^"']*)["']"#,
                #"source\s*:\s*["'](https?://[^"']+\.m3u8[^"']*)["']"#,
                #"src\s*=\s*["'](https?://[^"']+\.m3u8[^"']*)["']"#,
                #"https?://[^"'\s\\]+\.mp4[^"'\s\\]*"#
            ]
            
            for pattern in patterns {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: html.utf16.count)
                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    if match.numberOfRanges > 1 {
                        let matchedRange = match.range(at: 1)
                        if let r = Range(matchedRange, in: html) {
                            return String(html[r]).replacingOccurrences(of: "\\/", with: "/")
                        }
                    } else {
                        let matchedRange = match.range(at: 0)
                        if let r = Range(matchedRange, in: html) {
                            return String(html[r]).replacingOccurrences(of: "\\/", with: "/")
                        }
                    }
                }
            }
        } catch {
            print("Extraction error: \(error)")
        }
        return nil
    }
}
