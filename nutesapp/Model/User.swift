//
//  User.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class User {
    let uid: String
    let fullname: String
    let username: String
    let posts: Int
    let followers: Int
    let following: Int
    let isFollowing: Bool
    let imageUrl: String
    
    init(uid: String, fullname:String, username: String, posts: Int, followers:Int, following:Int, isFollowing: Bool, imageUrl: String) {
        self.uid = uid
        self.fullname = fullname
        self.username = username
        self.posts = posts
        self.followers = followers
        self.following = following
        self.isFollowing = isFollowing
        self.imageUrl = imageUrl
    }
    
    convenience init(uid: String, fullname:String, username: String) {
        self.init(uid: uid, fullname: fullname, username: username, posts: 0, followers: 0, following: 0, isFollowing: false, imageUrl: "")
    }
}

extension User: ListDiffable {
    
    func diffIdentifier() -> NSObjectProtocol {
        return uid as NSString
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard self !== object else { return true }
        guard let object = object as? User else { return false }
        return (self.uid) == (object.uid)
    }
    
}

