import UIKit
import Flutter
import flutter_local_notifications
import OneSignalFramework

@main
@objc class AppDelegate: FlutterAppDelegate {

    // ✅ Expose the Flutter engine to SceneDelegate if needed
    lazy var flutterEngine = FlutterEngine(name: "flutter_engine")

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Run Flutter engine
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: flutterEngine)

        // Initialize OneSignal
        OneSignal.initialize("f73d1186-4a67-4b6b-90be-e0319829d1cb", withLaunchOptions: launchOptions)

        // Request push permissions
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        })
        
        // ✅ Initialize Flutter local notifications plugin if used
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
