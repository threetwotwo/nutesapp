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
    
    let uid: String
    let fullname: String
    let email: String
    let username: String
    let url: String
    let followerCount: Int
    
    init(uid: String, fullname:String, email: String, username: String, url: String, followerCount: Int) {
        self.uid = uid
        self.fullname = fullname
        self.email = email
        self.username = username
        self.url = url
        self.followerCount = followerCount
    }
    
    convenience init(username: String) {
        self.init(uid: "", fullname: "", email: "", username: username, url: "", followerCount: 0)
    }
    
}

extension User: ListDiffable {
    
    func diffIdentifier() -> NSObjectProtocol {
        return username as NSString
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return true
    }
    
}

