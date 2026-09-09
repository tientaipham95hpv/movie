import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @ObservedObject var security = SecurityService.shared
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Trang Chủ", systemImage: "house.fill")
                    }
                    .tag(0)
                
                SearchView()
                    .tabItem {
                        Label("Tìm Kiếm", systemImage: "magnifyingglass")
                    }
                    .tag(1)
                
                DownloadsView()
                    .tabItem {
                        Label("Đã Tải", systemImage: "arrow.down.circle.fill")
                    }
                    .tag(2)
                
                FavoritesView()
                    .tabItem {
                        Label("Yêu Thích", systemImage: "heart.fill")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Label("Cài Đặt", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .accentColor(.blue)
            
            // Lock Screen Overlay when Face ID is enabled and app is locked
            if security.isFaceIDEnabled && !security.isUnlocked {
                LockScreenView()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
    }
}
