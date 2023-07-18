//
//  AppDelegate.swift
//  HGCam
//
//  Created by Aly Salman on 18/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // Check if it's the first launch
        let isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")
        
        if isFirstLaunch {
            // First launch, present the onboarding screen
            let onboardingViewController = OnboardingViewController()
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = onboardingViewController
            self.window = window
            
            // Set the flag to false to indicate that the onboarding has been completed
            UserDefaults.standard.set(false, forKey: "isFirstLaunch")
        } else {
            // Not the first launch, proceed with your app's main view controller
            let mainViewController = CameraViewController()
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = mainViewController
            self.window = window
        }
        
        window?.makeKeyAndVisible()
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

