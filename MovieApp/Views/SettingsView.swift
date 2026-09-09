import SwiftUI

struct SettingsView: View {
    @ObservedObject var security = SecurityService.shared
    @ObservedObject var history = HistoryService.shared
    @State private var showClearAlert = false
    
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
                        
                        // Section 1: Security
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BẢO MẬT & QUYỀN RIÊNG TƯ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                            
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.appAccentBlue.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "faceid")
                                        .foregroundColor(.appAccentBlue)
                                }
                                
                                Text("Khóa App Bằng Face ID")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $security.isFaceIDEnabled)
                                    .labelsHidden()
                                    .tint(.appAccentBlue)
                            }
                            .padding(14)
                            .glassCard(cornerRadius: 16)
                        }
                        .padding(.horizontal)
                        
                        // Section 2: Data Cache
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DỮ LIỆU & BỘ NHỚ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                            
                            Button(action: { showClearAlert = true }) {
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
                                .glassCard(cornerRadius: 16)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Section 3: Info
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
            .alert("Xóa Lịch Sử Xem", isPresented: $showClearAlert) {
                Button("Xóa Hẳn", role: .destructive) {
                    history.clearHistory()
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Bạn có chắc chắn muốn xóa toàn bộ lịch sử xem dở?")
            }
        }
        .navigationViewStyle(.stack)
    }
}
