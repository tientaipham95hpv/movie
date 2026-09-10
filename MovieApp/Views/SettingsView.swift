import SwiftUI

struct SettingsView: View {
    @ObservedObject var security = SecurityService.shared
    @ObservedObject var history = HistoryService.shared
    @ObservedObject var searchHistory = SearchHistoryService.shared
    
    @State private var showClearWatchAlert = false
    @State private var showClearSearchAlert = false
    @State private var selectedIcon: String = "default"
    @State private var iconAlertMessage: String?
    
    private let fakeIcons: [(id: String, name: String, icon: String, symbol: String)] = [
        ("default", "Mặc Định", "film", "film.fill"),
        ("calculator", "Máy Tính", "plus.slash.minus", "function"),
        ("notes", "Ghi Chú", "note.text", "square.and.pencil"),
        ("weather", "Thời Tiết", "sun.max.fill", "cloud.sun.fill"),
        ("clock", "Đồng Hồ", "clock.fill", "timer")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Header
                        Text("Cài Đặt")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Section 1: Security & Privacy
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BẢO MẬT & QUYỀN RIÊNG TƯ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                            
                            VStack(spacing: 0) {
                                // Face ID Lock
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.appAccentBlue.opacity(0.2))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "faceid")
                                            .foregroundColor(.appAccentBlue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Khóa App Bằng Face ID")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Yêu cầu Face ID khi mở lại app")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $security.isFaceIDEnabled)
                                        .labelsHidden()
                                        .tint(.appAccentBlue)
                                }
                                .padding(14)
                                
                                Divider().background(Color.appCardBorder)
                                
                                // Incognito Mode
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.appAccentPurple.opacity(0.2))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "eye.slash.fill")
                                            .foregroundColor(.appAccentPurple)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Chế Độ Ẩn Danh")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Tạm dừng lưu lịch sử xem & tìm kiếm")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $security.isIncognitoMode)
                                        .labelsHidden()
                                        .tint(.appAccentPurple)
                                }
                                .padding(14)
                            }
                            .glassCard(cornerRadius: 16)
                        }
                        .padding(.horizontal)
                        
                        // Section 2: Fake App Icon Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ĐỔI BIỂU TƯỢNG (FAKE APP ICON)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                            
                            VStack(spacing: 8) {
                                ForEach(fakeIcons, id: \.id) { item in
                                    Button(action: {
                                        switchAppIcon(to: item.id)
                                    }) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedIcon == item.id ? Color.appAccentBlue.opacity(0.25) : Color.appCardBg)
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: item.symbol)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(selectedIcon == item.id ? .appAccentBlue : .white.opacity(0.8))
                                            }
                                            
                                            Text(item.name)
                                                .font(.system(size: 14, weight: selectedIcon == item.id ? .bold : .medium))
                                                .foregroundColor(selectedIcon == item.id ? .white : .white.opacity(0.8))
                                            
                                            Spacer()
                                            
                                            if selectedIcon == item.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.appAccentBlue)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 14)
                                    }
                                    if item.id != fakeIcons.last?.id {
                                        Divider().background(Color.appCardBorder).padding(.leading, 60)
                                    }
                                }
                            }
                            .glassCard(cornerRadius: 16)
                        }
                        .padding(.horizontal)
                        
                        // Section 3: Data & Cache
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DỮ LIỆU & BỘ NHỚ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                            
                            VStack(spacing: 0) {
                                Button(action: { showClearWatchAlert = true }) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color.appAccentPink.opacity(0.2))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "trash")
                                                .foregroundColor(.appAccentPink)
                                        }
                                        
                                        Text("Xóa Lịch Sử Xem Dở")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.appAccentPink)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(14)
                                }
                                
                                Divider().background(Color.appCardBorder)
                                
                                Button(action: { showClearSearchAlert = true }) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color.appYellow.opacity(0.2))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "clock.arrow.2.circlepath")
                                                .foregroundColor(.appYellow)
                                        }
                                        
                                        Text("Xóa Lịch Sử Tìm Kiếm")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.appYellow)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(14)
                                }
                            }
                            .glassCard(cornerRadius: 16)
                        }
                        .padding(.horizontal)
                        
                        // Section 4: Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("THÔNG TIN DỊCH VỤ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Nguồn API 1")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("VSPHIM")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.appAccentBlue)
                                }
                                Divider().background(Color.appCardBorder)
                                HStack {
                                    Text("Nguồn API 2")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("AVDB API")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.appAccentPurple)
                                }
                                Divider().background(Color.appCardBorder)
                                HStack {
                                    Text("Phiên bản App")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("1.0.0 (Unsigned IPA)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(14)
                            .glassCard(cornerRadius: 16)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .alert("Xóa Lịch Sử Xem", isPresented: $showClearWatchAlert) {
                Button("Xóa Hẳn", role: .destructive) {
                    history.clearHistory()
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Bạn có chắc chắn muốn xóa toàn bộ lịch sử xem dở?")
            }
            .alert("Xóa Lịch Sử Tìm Kiếm", isPresented: $showClearSearchAlert) {
                Button("Xóa Hẳn", role: .destructive) {
                    searchHistory.clearHistory()
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Bạn có chắc chắn muốn xóa toàn bộ từ khóa tìm kiếm gần đây?")
            }
            .alert("Đổi Biểu Tượng", isPresented: Binding(
                get: { iconAlertMessage != nil },
                set: { if !$0 { iconAlertMessage = nil } }
            )) {
                Button("Đã hiểu", role: .cancel) {
                    iconAlertMessage = nil
                }
            } message: {
                Text(iconAlertMessage ?? "")
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if let current = UIApplication.shared.alternateIconName {
                selectedIcon = current
            } else {
                selectedIcon = "default"
            }
        }
    }
    
    private func switchAppIcon(to iconId: String) {
        guard UIApplication.shared.supportsAlternateIcons else {
            iconAlertMessage = "Thiết bị hoặc môi trường hiện tại không hỗ trợ đổi biểu tượng (supportsAlternateIcons = false)."
            return
        }
        let target = iconId == "default" ? nil : iconId
        UIApplication.shared.setAlternateIconName(target) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Lỗi đổi icon: \(error.localizedDescription)")
                    self.iconAlertMessage = "Không thể đổi biểu tượng: \(error.localizedDescription)"
                } else {
                    self.selectedIcon = iconId
                }
            }
        }
    }
}
