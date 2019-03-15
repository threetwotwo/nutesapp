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
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate, MessagingDelegate {

    var window: UIWindow?
    
    //Present VC modally
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = tabBarController.viewControllers?.index(of: viewController)
        
        if viewController is UINavigationController,
            let vc = viewController.children.first as? UserViewController {
           vc.user = FirestoreManager.shared.currentUser

        }
        
        if viewController is createPostViewController {
            if let newVC = tabBarController.storyboard?.instantiateViewController(withIdentifier: "CreatePostVC") {
                tabBarController.present(newVC, animated: true)
                return false
            }
        }
        
        return true
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //Configures a default Firebase app.
        FirebaseApp.configure()
        
        //Delegate to handle FCM token refreshes, and remote data messages received via FCM direct channel
        Messaging.messaging().delegate = self

        //Initialize a manager for firestore operations
        let firestore = FirestoreManager.shared
        firestore.db = Firestore.firestore()
        firestore.configureDB()
        
        //Requests the notification settings for this app.
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            
            let alertSetting = settings.alertSetting ==
                UNNotificationSetting.enabled ? "enabled" : "disabled"
            let soundSetting = settings.soundSetting ==
                UNNotificationSetting.enabled ? "enabled" : "disabled"
            
            print("Alert setting is \(alertSetting)")
            print("Sound setting is \(soundSetting)")
        }
        
        //Register for remote notifications
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
            
            print("***Current User profile***")
            print(user.debugDescription)
            print("provider: \(user.providerID)")
            print("uid: \(user.uid)")
            print("display name: \(user.displayName ?? "nil")")
            print("email: \(user.email ?? "nil")")
            print("photo: \(user.photoURL)")
            print("isEmailVerified: \(user.isEmailVerified)")
            print("***Current User profile***")

//            if !user.isEmailVerified {
//                Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
//                    print("@@@@ sendEmailVerification @@@")
//                })
//            }
            
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
    
    //Called when Registration for Remote Notifications is successful
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var readableToken: String = ""
        for i in 0..<deviceToken.count {
            readableToken += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        print("Received an APNs device token: \(readableToken)")
        
    }
    
    //Called when Registration for Remote Notifications Fails
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Registration failed!")
    }
    
    
    /**
    
    This method will be called once a token is available, or has been refreshed. Typically it will be called once per app start, but may be called more often, if token is invalidated or updated. When this method is called, it is the ideal time to:
     
     1. If the registration token is new, send it to your application server.
     2. Subscribe the registration token to topics. This is required only for new subscriptions or for situations where the user has re-installed the app
     
 **/

    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
            }
        }
    }
    
    
    //Called When Silent Push Notification Arrives
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("Entire message \(userInfo)")
        
        let state : UIApplication.State = application.applicationState
        switch state {
        case UIApplication.State.active:
            print("If needed notify user about the message")
        default:
            print("Run code to download content")
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
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


// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {

    //Called when Cloud Message Arrives While App is in Foreground
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let userInfo = notification.request.content.userInfo
        
//        debugPrint(userInfo)
        //Handle the notification ON APP
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler([.sound,.alert,.badge])
    }

    //Called When Cloud Message is Received While App is in Background or is Closed
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
//        if let messageID = userInfo[gcmMessageIDKey] {
//            debugPrint("Message ID: \(messageID)")
//        }
        //Handle the notification ON BACKGROUND
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler()
    }
}
// [END ios_10_message_handling]
