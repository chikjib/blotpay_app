//
//  SceneDelegate.swift
//  Runner
//
//  Created by Chikjib on 26/10/2025.
//


import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var flutterEngine: FlutterEngine?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        // ✅ Access the shared Flutter engine from AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        flutterEngine = appDelegate.flutterEngine

        // ✅ Use that engine for the FlutterViewController
        let flutterViewController = FlutterViewController(engine: flutterEngine!, nibName: nil, bundle: nil)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = flutterViewController
        self.window = window
        window.makeKeyAndVisible()
    }
}
