import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

public extension View {
    func forceOrientation(_ orientation: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = orientation
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let geom = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation.contains(.landscape) ? .landscapeRight : .portrait)
                windowScene.requestGeometryUpdate(geom) { _ in }
            }
        } else {
            let val = orientation.contains(.landscape) ? UIInterfaceOrientation.landscapeRight.rawValue : UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(val, forKey: "orientation")
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }
}

@main
struct MovieAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
