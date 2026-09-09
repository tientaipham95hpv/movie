import SwiftUI

public class ImageLoader: ObservableObject {
    @Published public var image: UIImage?
    @Published public var isLoading = false
    
    private static let cache = NSCache<NSString, UIImage>()
    
    public init() {}
    
    public func load(urlString: String) {
        guard !urlString.isEmpty else { return }
        
        let cacheKey = NSString(string: urlString)
        if let cached = ImageLoader.cache.object(forKey: cacheKey) {
            self.image = cached
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        
        self.isLoading = true
        var request = URLRequest(url: url)
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.addValue("image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data, let uiImage = UIImage(data: data) {
                    ImageLoader.cache.setObject(uiImage, forKey: cacheKey)
                    self.image = uiImage
                }
            }
        }.resume()
    }
}

public struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    @StateObject private var loader = ImageLoader()
    let urlString: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    public init(
        urlString: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }
    
    public var body: some View {
        Group {
            if let uiImage = loader.image {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .onAppear {
            loader.load(urlString: urlString)
        }
        .onChange(of: urlString) { newURL in
            loader.load(urlString: newURL)
        }
    }
}
