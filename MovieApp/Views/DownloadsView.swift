import SwiftUI
import AVKit

struct DownloadsView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @State private var playingDownload: DownloadedEpisode?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 14) {
                    // Title Header
                    HStack {
                        Text("Quản Lý Tải Xuống")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if downloadManager.isDownloading {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Đang tải tập phim...")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                ProgressView(value: downloadManager.currentDownloadProgress)
                                    .tint(.appAccentBlue)
                            }
                            Button("Hủy") {
                                downloadManager.cancelDownload()
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.appAccentPink)
                        }
                        .padding(14)
                        .glassCard(cornerRadius: 16)
                        .padding(.horizontal)
                    }
                    
                    if downloadManager.downloads.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.appCardBg)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                            Text("Chưa Có Phim Tải Về")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Các tập phim đã tải xuống sẽ xuất hiện tại đây để xem offline không cần 4G/Wi-Fi.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(downloadManager.downloads) { item in
                                    HStack(spacing: 14) {
                                        AsyncImage(url: URL(string: item.posterURL)) { phase in
                                            if let img = phase.image {
                                                img.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                Rectangle().fill(Color.appCardBg)
                                            }
                                        }
                                        .frame(width: 70, height: 90)
                                        .cornerRadius(12)
                                        .clipped()
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(item.movieTitle)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                            
                                            Text(item.episodeName)
                                                .font(.caption)
                                                .foregroundColor(.appAccentBlue)
                                            
                                            Text(item.formattedSize)
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                playingDownload = item
                                            }) {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.appAccentPurple)
                                            }
                                            
                                            Button(action: {
                                                downloadManager.deleteDownload(id: item.id)
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding(10)
                                    .glassCard(cornerRadius: 16)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                downloadManager.loadDownloads()
            }
            .fullScreenCover(item: $playingDownload) { item in
                let player = AVPlayer(url: URL(fileURLWithPath: item.localFilePath))
                VideoPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear { player.play() }
            }
        }
    }
}
