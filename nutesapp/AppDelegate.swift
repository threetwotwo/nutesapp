//
//  AppDelegate.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate, UNUserNotificationCenterDelegate, MessagingDelegate  {

    var window: UIWindow?
    
    //Present VC modally
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is createPostViewController {
            if let newVC = tabBarController.storyboard?.instantiateViewController(withIdentifier: "CreatePostVC") {
                tabBarController.present(newVC, animated: true)
                return false
            }
        }
        
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
            }
        }
        let firestore = FirestoreManager.shared
        firestore.db = Firestore.firestore()
        firestore.configureDB()
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        if let user = Auth.auth().currentUser {
            
            guard let username = UserDefaults.standard.string(forKey: "username"),
            let fullname = UserDefaults.standard.string(forKey: "fullname")
            else {
                return false
            }
            
            //get from user defaults
            let postCount = UserDefaults.standard.integer(forKey: "postCount")
            let followers = UserDefaults.standard.integer(forKey: "followerCount")
            let following = UserDefaults.standard.integer(forKey: "followingCount")
            let url = UserDefaults.standard.string(forKey: "url") ?? ""
            
            firestore.currentUser = User(uid: user.uid, fullname: fullname, email: user.email ?? "", username: username, url: url, followerCount: followers)
            
            let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainscreen") as! UITabBarController
            self.window?.rootViewController = tabBarController
            self.window?.makeKeyAndVisible()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

