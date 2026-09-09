import SwiftUI
import AVKit

struct DownloadsView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @State private var playingDownload: DownloadedEpisode?
    
    var body: some View {
        NavigationView {
            VStack {
                if downloadManager.isDownloading {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Đang tải phim...")
                                .font(.caption)
                                .fontWeight(.bold)
                            ProgressView(value: downloadManager.currentDownloadProgress)
                        }
                        Button("Hủy") {
                            downloadManager.cancelDownload()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                if downloadManager.downloads.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Chưa có phim tải về")
                            .font(.headline)
                        Text("Các tập phim đã tải xuống sẽ xuất hiện tại đây để xem offline không cần mạng.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(downloadManager.downloads) { item in
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: item.posterURL)) { phase in
                                    if let img = phase.image {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle().fill(Color.gray.opacity(0.3))
                                    }
                                }
                                .frame(width: 60, height: 80)
                                .cornerRadius(8)
                                .clipped()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.movieTitle)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .lineLimit(2)
                                    Text(item.episodeName)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(item.formattedSize)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    playingDownload = item
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                let item = downloadManager.downloads[idx]
                                downloadManager.deleteDownload(id: item.id)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Tải Xuống")
            .navigationBarTitleDisplayMode(.inline)
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
