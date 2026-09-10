import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

public extension View {
    func forceOrientation(_ orientation: UIInterfaceOrientationMask) {
        let isLandscape = !orientation.intersection([.landscape, .landscapeLeft, .landscapeRight]).isEmpty
        AppDelegate.orientationLock = isLandscape ? .landscape : (UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait)
        
        let targetOrientation: UIInterfaceOrientation = isLandscape ? .landscapeRight : .portrait
        UIDevice.current.setValue(targetOrientation.rawValue, forKey: "orientation")
        
        if #available(iOS 16.0, *) {
            DispatchQueue.main.async {
                let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                for scene in scenes {
                    let geom = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: isLandscape ? .landscapeRight : .portrait)
                    scene.requestGeometryUpdate(geom) { _ in }
                }
            }
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
