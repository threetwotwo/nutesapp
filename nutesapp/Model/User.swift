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
    let username: String
    let posts: Int
    let isFollowing: Bool
    
    init(uid: String, username: String, posts: Int, isFollowing: Bool) {
        self.uid = uid
        self.username = username
        self.posts = posts
        self.isFollowing = isFollowing
    }
    
    convenience init(uid: String, username: String) {
        self.init(uid: uid, username: username, posts: 0, isFollowing: false)
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

