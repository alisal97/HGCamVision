
//
//  AppDelegate.swift
//  HGCam
//
//  Created by Aly Salman on 18/02/23.
//
import UIKit
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set the initial value of isFirstLaunch
        if UserDefaults.standard.object(forKey: "isFirstLaunch") == nil {
            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
        }
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Reset isFirstLaunch when the app becomes active
        UserDefaults.standard.set(true, forKey: "isFirstLaunch")
    }

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
