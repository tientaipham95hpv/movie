import SwiftUI
import AVKit
import MediaPlayer

// MARK: - AirPlay Route Picker Button
struct AirPlayButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.activeTintColor = UIColor(Color.appAccentBlue)
        routePickerView.tintColor = .white
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - Premium Native Video Player Container
struct NativePlayerContainerView: View {
    let movie: UnifiedMovie
    @State var episode: UnifiedEpisode
    
    @State private var streamURL: String?
    @State private var isLoading = true
    @State private var useWebViewFallback = false
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var playbackRate: Float = 1.0
    @State private var currentTime: Double = 0.0
    @State private var duration: Double = 0.0
    @State private var showControls = true
    @State private var videoGravity: AVLayerVideoGravity = .resizeAspect
    @State private var isSeeking = false
    @State private var seekTime: Double = 0.0
    
    // Gestures HUD
    @State private var showBrightnessHUD = false
    @State private var brightnessValue: CGFloat = UIScreen.main.brightness
    @State private var showVolumeHUD = false
    @State private var volumeValue: Float = AVAudioSession.sharedInstance().outputVolume
    @State private var showSeekAnimation: String? = nil
    
    @Environment(\.dismiss) var dismiss
    private let rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appAccentBlue))
                        .scaleEffect(1.3)
                    Text("Đang tối ưu luồng m3u8 trình phát Native...")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                }
            } else if useWebViewFallback || streamURL == nil {
                PlayerScreenView(episode: episode, movieTitle: movie.title)
            } else if let player = player {
                ZStack {
                    VideoPlayerViewRepresentable(player: player, videoGravity: videoGravity)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showControls.toggle()
                            }
                        }
                    
                    // Gesture Detectors (Brightness Left, Volume Right, Double Tap Seek)
                    HStack(spacing: 0) {
                        // Left Half - Brightness / Double Tap -10s
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 10)
                                    .onChanged { val in
                                        let delta = -val.translation.height / 300.0
                                        let newB = max(0, min(1, brightnessValue + delta))
                                        UIScreen.main.brightness = newB
                                        showBrightnessHUD = true
                                    }
                                    .onEnded { _ in
                                        brightnessValue = UIScreen.main.brightness
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            showBrightnessHUD = false
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                seekBy(-10)
                                triggerRipple("-10s")
                            }
                        
                        // Right Half - Volume / Double Tap +10s
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 10)
                                    .onChanged { val in
                                        let delta = Float(-val.translation.height / 300.0)
                                        let newV = max(0, min(1, volumeValue + delta))
                                        MPVolumeView.setVolume(newV)
                                        volumeValue = newV
                                        showVolumeHUD = true
                                    }
                                    .onEnded { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            showVolumeHUD = false
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                seekBy(10)
                                triggerRipple("+10s")
                            }
                    }
                    .edgesIgnoringSafeArea(.all)
                    
                    // Double Tap Ripple Animation Overlay
                    if let text = showSeekAnimation {
                        Text(text)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Circle())
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Volume & Brightness Floating HUD Indicators
                    if showBrightnessHUD {
                        VStack(spacing: 8) {
                            Image(systemName: "sun.max.fill").font(.title2).foregroundColor(.appYellow)
                            ProgressView(value: Double(UIScreen.main.brightness))
                                .frame(width: 100)
                                .tint(.appYellow)
                        }
                        .padding(12)
                        .glassCard(cornerRadius: 12)
                    }
                    
                    if showVolumeHUD {
                        VStack(spacing: 8) {
                            Image(systemName: "speaker.wave.3.fill").font(.title2).foregroundColor(.appAccentBlue)
                            ProgressView(value: Double(volumeValue))
                                .frame(width: 100)
                                .tint(.appAccentBlue)
                        }
                        .padding(12)
                        .glassCard(cornerRadius: 12)
                    }
                    
                    // Controls Overlay (Top Header & Bottom Bar)
                    if showControls {
                        VStack {
                            topControlBar(player: player)
                            
                            Spacer()
                            
                            centerControlButtons(player: player)
                            
                            Spacer()
                            
                            bottomControlBar(player: player)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onAppear {
            forceOrientation(.landscapeRight)
            extractAndPreparePlayer()
        }
        .onDisappear {
            forceOrientation(.portrait)
            saveProgress()
            player?.pause()
        }
    }
    
    // MARK: - Top Header Controls
    private func topControlBar(player: AVPlayer) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                forceOrientation(.portrait)
                saveProgress()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(movie.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(episode.name)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            AirPlayButtonView()
                .frame(width: 34, height: 34)
            
            Button(action: {
                if videoGravity == .resizeAspect { videoGravity = .resizeAspectFill }
                else if videoGravity == .resizeAspectFill { videoGravity = .resize }
                else { videoGravity = .resizeAspect }
            }) {
                Image(systemName: videoGravity == .resizeAspectFill ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
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
                    .background(Color.white.opacity(0.25))
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.85), Color.clear], startPoint: .top, endPoint: .bottom)
        )
    }
    
    // MARK: - Center Action Buttons
    private func centerControlButtons(player: AVPlayer) -> some View {
        HStack(spacing: 40) {
            Button(action: { seekBy(-10) }) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            Button(action: {
                if isPlaying {
                    player.pause()
                    isPlaying = false
                } else {
                    player.play()
                    isPlaying = true
                }
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.appAccentBlue)
            }
            
            Button(action: { seekBy(10) }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Bottom Bar Timeline Controls
    private func bottomControlBar(player: AVPlayer) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(formatTime(isSeeking ? seekTime : currentTime))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                
                Slider(
                    value: Binding(
                        get: { isSeeking ? seekTime : currentTime },
                        set: { seekTime = $0 }
                    ),
                    in: 0...max(1, duration),
                    onEditingChanged: { editing in
                        isSeeking = editing
                        if !editing {
                            player.seek(to: CMTime(seconds: seekTime, preferredTimescale: 1))
                            currentTime = seekTime
                        }
                    }
                )
                .accentColor(.appAccentBlue)
                
                Text(formatTime(duration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
        .background(
            LinearGradient(colors: [Color.clear, Color.black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
        )
    }
    
    private func seekBy(_ seconds: Double) {
        guard let p = player else { return }
        let target = max(0, min(duration, currentTime + seconds))
        p.seek(to: CMTime(seconds: target, preferredTimescale: 1))
        currentTime = target
    }
    
    private func triggerRipple(_ text: String) {
        showSeekAnimation = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showSeekAnimation = nil
        }
    }
    
    private func extractAndPreparePlayer() {
        Task {
            let embed = episode.embedURL
            // Check if it is a local offline file path
            if embed.hasPrefix("file://") || FileManager.default.fileExists(atPath: embed) {
                let fileURL = embed.hasPrefix("file://") ? (URL(string: embed) ?? URL(fileURLWithPath: embed)) : URL(fileURLWithPath: embed)
                await MainActor.run {
                    self.streamURL = embed
                    let avPlayer = AVPlayer(url: fileURL)
                    self.player = avPlayer
                    self.isLoading = false
                    self.isPlaying = true
                    avPlayer.play()
                    
                    avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
                        if let item = avPlayer.currentItem {
                            self.currentTime = time.seconds
                            let d = item.duration.seconds
                            self.duration = d.isNaN || d.isInfinite ? 0 : d
                        }
                    }
                }
                return
            }
            
            if let directURL = await HLSExtractorService.shared.extractStreamURL(from: embed),
               let url = URL(string: directURL) {
                await MainActor.run {
                    self.streamURL = directURL
                    let avPlayer = AVPlayer(url: url)
                    self.player = avPlayer
                    self.isLoading = false
                    self.isPlaying = true
                    avPlayer.play()
                    
                    avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
                        if let item = avPlayer.currentItem {
                            self.currentTime = time.seconds
                            let d = item.duration.seconds
                            self.duration = d.isNaN || d.isInfinite ? 0 : d
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
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let sec = Int(seconds)
        let h = sec / 3600
        let m = (sec % 3600) / 60
        let s = sec % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

// MARK: - Custom AVPlayerLayer Video View
struct VideoPlayerViewRepresentable: UIViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.player = player
        view.playerLayer.videoGravity = videoGravity
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.videoGravity = videoGravity
    }
}

class PlayerUIView: UIView {
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }
}

// MARK: - MPVolumeView Helper for Volume Gesture
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            slider?.value = volume
        }
    }
}
