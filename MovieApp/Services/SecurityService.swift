import Foundation
import LocalAuthentication

public class SecurityService: ObservableObject {
    public static let shared = SecurityService()
    
    private let faceIDKey = "AppSecurity_FaceID_Enabled"
    
    @Published public var isFaceIDEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isFaceIDEnabled, forKey: faceIDKey)
        }
    }
    
    @Published public var isUnlocked: Bool = true
    
    public init() {
        self.isFaceIDEnabled = UserDefaults.standard.bool(forKey: faceIDKey)
        if self.isFaceIDEnabled {
            self.isUnlocked = false
        }
    }
    
    public func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        let reason = "Xác thực Face ID / Touch ID để bảo vệ ứng dụng Phim Hay."
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        completion(true)
                    } else {
                        self.isUnlocked = false
                        completion(false)
                    }
                }
            }
        } else {
            // Fallback to passcode or auto pass in simulator
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    self.isUnlocked = success
                    completion(success)
                }
            }
        }
    }
    
    public func lockApp() {
        if isFaceIDEnabled {
            isUnlocked = false
        }
    }
}
