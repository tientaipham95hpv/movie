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
    @State private var showHeader = true
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                PlayerView(urlString: episode.embedURL)
                    .edgesIgnoringSafeArea(.all)
            }
            .edgesIgnoringSafeArea(.all)
            
            // Header back button & title
            if showHeader {
                HStack(spacing: 12) {
                    Button(action: {
                        forceOrientation(.portrait)
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .bold))
                            Text("Thoát")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.65))
                        .clipShape(Capsule())
                    }
                    
                    Text("\(movieTitle) - \(episode.name)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showHeader = false
                        }
                    }) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .transition(.opacity)
            } else {
                // Subtle mini floating exit button always available
                Button(action: {
                    forceOrientation(.portrait)
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(9)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(.leading, 16)
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onAppear {
            forceOrientation(.landscapeRight)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showHeader = false
                }
            }
        }
        .onDisappear {
            forceOrientation(.portrait)
        }
    }
}
