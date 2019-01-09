//
//  User.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class User: Codable {
    private var identifier: String = UUID().uuidString

    let uid: String
    let fullname: String
    let email: String
    let username: String
    let postCount: Int
    let followerCount: Int
    let followingCount: Int
    var isFollowing: Bool
    let url: String
    
    init(uid: String, fullname:String, email: String, username: String, postCount: Int, followerCount:Int, followingCount:Int, isFollowing: Bool, url: String) {
        self.uid = uid
        self.fullname = fullname
        self.email = email
        self.username = username
        self.postCount = postCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.isFollowing = isFollowing
        self.url = url
    }
    
    convenience init(uid: String, fullname:String, username: String) {
        self.init(uid: uid, fullname: fullname, email: "", username: username, postCount: 0, followerCount: 0, followingCount: 0, isFollowing: false, url: "")
    }
}

extension User: ListDiffable {
    
    func diffIdentifier() -> NSObjectProtocol {
        return identifier as NSString
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard self !== object else { return true }
        guard let object = object as? User else { return false }
        return (self.username) == (object.username)
    }
    
}

