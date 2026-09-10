import Foundation

public class HLSExtractorService {
    public static let shared = HLSExtractorService()
    
    private let session: URLSession
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        self.session = URLSession(configuration: config)
    }
    
    /// Extract direct .m3u8 or .mp4 stream URL from an embed webpage URL
    public func extractStreamURL(from embedURL: String) async -> String? {
        let trimmed = embedURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // 1. Direct check: if already ends with or contains .m3u8 or .mp4 directly
        if trimmed.hasPrefix("http") && (trimmed.contains(".m3u8") || trimmed.contains(".mp4")) {
            if let paramURL = extractURLFromQueryParams(trimmed) {
                return paramURL
            }
            if !trimmed.contains("player.phimapi.com") && !trimmed.contains("share/") && !trimmed.contains("embed") {
                return trimmed
            }
        }
        
        // 2. Query param check for embedded stream parameter
        if let paramURL = extractURLFromQueryParams(trimmed) {
            return paramURL
        }
        
        // 3. HTML Content Fetch & Regex Parsing (with depth up to 2 for iframes)
        return await fetchAndParseHTML(urlString: trimmed, depth: 0)
    }
    
    private func extractURLFromQueryParams(_ urlString: String) -> String? {
        guard let components = URLComponents(string: urlString) else { return nil }
        let targetKeys = ["url", "file", "src", "link", "v", "video", "source", "m3u8"]
        
        for item in components.queryItems ?? [] {
            if targetKeys.contains(item.name.lowercased()), let val = item.value {
                let decoded = val.removingPercentEncoding ?? val
                if (decoded.contains(".m3u8") || decoded.contains(".mp4")) && (decoded.hasPrefix("http://") || decoded.hasPrefix("https://")) {
                    return decoded
                }
            }
        }
        return nil
    }
    
    private func fetchAndParseHTML(urlString: String, depth: Int) async -> String? {
        guard depth < 3, let url = URL(string: urlString) else { return nil }
        
        var req = URLRequest(url: url)
        req.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        if let host = url.host {
            req.addValue("https://\(host)/", forHTTPHeaderField: "Referer")
        }
        
        do {
            let (data, _) = try await session.data(for: req)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            let cleanHTML = html
                .replacingOccurrences(of: "\\/", with: "/")
                .replacingOccurrences(of: "\\u002F", with: "/")
                .replacingOccurrences(of: "&amp;", with: "&")
            
            // Search for direct .m3u8 / .mp4 URLs in HTML/JS string literals
            let patterns = [
                #""m3u8"\s*:\s*["']([^"']+)["']"#,
                #"file\s*:\s*["']([^"']+\.m3u8[^"']*)["']"#,
                #"source\s*:\s*["']([^"']+\.m3u8[^"']*)["']"#,
                #"url\s*:\s*["']([^"']+\.m3u8[^"']*)["']"#,
                #"src\s*:\s*["']([^"']+\.m3u8[^"']*)["']"#,
                #"https?://[^\s"'\\]+\.m3u8[^\s"'\\]*"#,
                #"https?://[^\s"'\\]+\.mp4[^\s"'\\]*"#
            ]
            
            for pattern in patterns {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: cleanHTML.utf16.count)
                let matches = regex.matches(in: cleanHTML, options: [], range: range)
                
                for match in matches {
                    var targetStr = ""
                    if match.numberOfRanges > 1 {
                        let matchedRange = match.range(at: 1)
                        if let r = Range(matchedRange, in: cleanHTML) {
                            targetStr = String(cleanHTML[r])
                        }
                    } else {
                        let matchedRange = match.range(at: 0)
                        if let r = Range(matchedRange, in: cleanHTML) {
                            targetStr = String(cleanHTML[r])
                        }
                    }
                    
                    targetStr = targetStr.trimmingCharacters(in: .whitespacesAndNewlines)
                    if targetStr.hasPrefix("http://") || targetStr.hasPrefix("https://") {
                        if targetStr.contains(".m3u8") || targetStr.contains(".mp4") {
                            return targetStr
                        }
                    }
                }
            }
            
            // Look for IFRAME src tags recursively
            let iframeRegex = try NSRegularExpression(pattern: #"<iframe[^>]+src=["']([^"']+)["']"#, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: cleanHTML.utf16.count)
            if let iframeMatch = iframeRegex.firstMatch(in: cleanHTML, options: [], range: range),
               let r = Range(iframeMatch.range(at: 1), in: cleanHTML) {
                var iframeSrc = String(cleanHTML[r])
                if iframeSrc.hasPrefix("//") {
                    iframeSrc = "https:" + iframeSrc
                } else if iframeSrc.hasPrefix("/") {
                    if let scheme = url.scheme, let host = url.host {
                        iframeSrc = "\(scheme)://\(host)\(iframeSrc)"
                    }
                }
                if let extractedFromIframe = await fetchAndParseHTML(urlString: iframeSrc, depth: depth + 1) {
                    return extractedFromIframe
                }
            }
        } catch {
            print("HLSExtractor error: \(error)")
        }
        
        return nil
    }
}

