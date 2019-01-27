//
//  UserDataViewModel.swift
//  nutesapp
//
//  Created by Gary Piong on 24/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class UserDataViewModel: Codable {
    
    let username: String
    let postCount: String
    let followerCount: String
    let followingCount: String
    let isFollowing: Bool
    
    init(username: String, postCount: String, followerCount: String, followingCount: String, isFollowing: Bool) {
        self.username = username
        self.postCount = postCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.isFollowing = isFollowing
    }

}

extension UserDataViewModel: ListDiffable {
    
    func diffIdentifier() -> NSObjectProtocol {
        return username as NSString
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return true
    }
    
}

