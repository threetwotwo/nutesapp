//
//  UserDefaultsManager.swift
//  nutesapp
//
//  Created by Gary Piong on 08/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation

final class UserDefaultsManager {
    
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    
    func saveUser(user: User) {
        //Get saved users
        if var savedUsers = self.defaults.array(forKey: "savedUsers") as? [User] {
            //Append new user
            savedUsers.append(user)
            //Save updated array
            if let encoded = try? self.encoder.encode(savedUsers) {
                let defaults = UserDefaults.standard
                defaults.set(encoded, forKey: "savedUsers")
            }
        }
    }
    
    func updateCurrentUser(user: User) {
        self.defaults.set(user.uid, forKey: "uid")
        self.defaults.set(user.fullname, forKey: "fullname")
        self.defaults.set(user.email, forKey: "email")
        self.defaults.set(user.username, forKey: "username")
        self.defaults.set(user.postCount, forKey: "postCount")
        self.defaults.set(user.followerCount, forKey: "followerCount")
        self.defaults.set(user.followingCount, forKey: "followingCount")
        self.defaults.set(user.url, forKey: "url")
    }
}
