import SwiftUI

struct LockScreenView: View {
    @ObservedObject var security = SecurityService.shared
    @State private var authError: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "faceid")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Phim Hay Ứng Dụng Đã Khóa")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Vui lòng xác thực bằng Face ID hoặc Touch ID để tiếp tục.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let err = authError {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button(action: authenticate) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text("Mở Khóa")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                
                Spacer()
            }
        }
        .onAppear {
            authenticate()
        }
    }
    
    private func authenticate() {
        security.authenticateUser { success in
            if !success {
                authError = "Xác thực thất bại. Bấm mở khóa để thử lại."
            }
        }
    }
}
