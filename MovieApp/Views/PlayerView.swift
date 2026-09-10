import SwiftUI
import WebKit

struct PlayerView: UIViewRepresentable {
    let urlString: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Inject AdBlocker script
        let userScript = AdBlockerService.shared.adBlockUserScript
        configuration.userContentController.addUserScript(userScript)
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let currentURL = uiView.url?.absoluteString, currentURL != urlString {
            if let url = URL(string: urlString) {
                uiView.load(URLRequest(url: url))
            }
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: PlayerView
        
        init(_ parent: PlayerView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                let scheme = url.scheme?.lowercased() ?? ""
                if scheme != "http" && scheme != "https" {
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}

struct PlayerScreenView: View {
    let episode: UnifiedEpisode
    let movieTitle: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            VStack {
                PlayerView(urlString: episode.embedURL)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Header back button & title
            HStack {
                Button(action: {
                    rotateToPortrait()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.85))
                        .padding()
                }
                
                Text("\(movieTitle) - \(episode.name)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]), startPoint: .top, endPoint: .bottom)
            )
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onAppear {
            rotateToLandscape()
        }
        .onDisappear {
            rotateToPortrait()
        }
    }
    
    private func rotateToLandscape() {
        forceOrientation(.landscapeRight)
    }
    
    private func rotateToPortrait() {
        forceOrientation(.portrait)
    }
}
