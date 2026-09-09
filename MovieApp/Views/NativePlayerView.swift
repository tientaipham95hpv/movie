import SwiftUI
import AVKit
import MediaPlayer

struct AirPlayButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.activeTintColor = .systemBlue
        routePickerView.tintColor = .white
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

struct NativePlayerContainerView: View {
    let movie: UnifiedMovie
    let episode: UnifiedEpisode
    
    @State private var streamURL: String?
    @State private var isLoading = true
    @State private var useWebViewFallback = false
    @State private var player: AVPlayer?
    @State private var playbackRate: Float = 1.0
    @State private var isPlaying = true
    @State private var currentTime: Double = 0.0
    @State private var duration: Double = 0.0
    
    @Environment(\.dismiss) var dismiss
    
    private let rates: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Đang bóc tách luồng video m3u8...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else if useWebViewFallback || streamURL == nil {
                // Fallback to WKWebView embed player
                PlayerScreenView(episode: episode, movieTitle: movie.title)
            } else if let player = player {
                // Native AVPlayer UI
                ZStack(alignment: .topLeading) {
                    VideoPlayer(player: player)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Controls Overlay Top
                    VStack {
                        HStack {
                            Button(action: {
                                saveProgress()
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            Text("\(movie.title) - \(episode.name)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // AirPlay Button
                            AirPlayButtonView()
                                .frame(width: 30, height: 30)
                            
                            // Speed Menu
                            Menu {
                                ForEach(rates, id: \.self) { rate in
                                    Button("\(String(format: "%.2fx", rate))") {
                                        playbackRate = rate
                                        player.rate = rate
                                    }
                                }
                            } label: {
                                Text("\(String(format: "%.1fx", playbackRate))")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]), startPoint: .top, endPoint: .bottom)
                        )
                        
                        Spacer()
                    }
                }
                .onDisappear {
                    saveProgress()
                    player.pause()
                }
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onAppear {
            extractAndPreparePlayer()
        }
    }
    
    private func extractAndPreparePlayer() {
        Task {
            if let directURL = await HLSExtractorService.shared.extractStreamURL(from: episode.embedURL),
               let url = URL(string: directURL) {
                await MainActor.run {
                    self.streamURL = directURL
                    let avPlayer = AVPlayer(url: url)
                    self.player = avPlayer
                    self.isLoading = false
                    avPlayer.play()
                    
                    // Start periodic history tracking
                    avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 5, preferredTimescale: 1), queue: .main) { time in
                        if let item = avPlayer.currentItem {
                            self.currentTime = time.seconds
                            self.duration = item.duration.seconds
                            if self.duration > 0 {
                                HistoryService.shared.saveProgress(
                                    movie: self.movie,
                                    episode: self.episode,
                                    currentTime: self.currentTime,
                                    duration: self.duration
                                )
                            }
                        }
                    }
                }
            } else {
                await MainActor.run {
                    self.useWebViewFallback = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveProgress() {
        if currentTime > 0 && duration > 0 {
            HistoryService.shared.saveProgress(
                movie: movie,
                episode: episode,
                currentTime: currentTime,
                duration: duration
            )
        }
    }
}
