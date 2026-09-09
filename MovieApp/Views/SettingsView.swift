import SwiftUI

struct SettingsView: View {
    @ObservedObject var security = SecurityService.shared
    @ObservedObject var history = HistoryService.shared
    @State private var showClearAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("BẢO MẬT & MẬT MÃ")) {
                    Toggle(isOn: $security.isFaceIDEnabled) {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(.blue)
                            Text("Khóa App Bằng Face ID")
                        }
                    }
                }
                
                Section(header: Text("DỮ LIỆU & BỘ NHỚ CACHE")) {
                    Button(action: {
                        showClearAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Xóa Lịch Sử Xem Dở")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("THÔNG TIN ĐƠN VỊ CUNG CẤP API")) {
                    HStack {
                        Text("Nguồn 1")
                        Spacer()
                        Text("VSPHIM (nguon.vsphim.com)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Nguồn 2")
                        Spacer()
                        Text("AVDB API (avdbapi.com)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Phiên bản App")
                        Spacer()
                        Text("1.0.0 (Build Unsigned IPA)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Cài Đặt")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Xóa Lịch Sử Xem", isPresented: $showClearAlert) {
                Button("Xóa Hẳn", role: .destructive) {
                    history.clearHistory()
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Bạn có chắc chắn muốn xóa toàn bộ lịch sử xem dở?")
            }
        }
    }
}
