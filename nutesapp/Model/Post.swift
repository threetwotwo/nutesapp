//
//  Post.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit
import FirebaseFirestore

class Post {
    
    private var identifier: String = UUID().uuidString
    let id: String
    let username: String
    let timestamp: Date
    let url: URL
    let likes: Int
    let followedUsernames: [String]
    let didLike: Bool
    let comments: [Comment]
    
    init(id: String, username: String, timestamp: Date, url: URL, likes: Int, followedUsernames: [String], didLike: Bool, comments: [Comment]) {
        self.id = id
        self.username = username
        self.timestamp = timestamp
        self.url = url
        self.likes = likes
        self.followedUsernames = followedUsernames
        self.didLike = didLike
        self.comments = comments
    }
}

extension Post: ListDiffable {
    
    func diffIdentifier() -> NSObjectProtocol {
        return (identifier) as NSString
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard self !== object else { return true }
        guard let object = object as? Post else { return false }
        return (self.identifier) == (object.identifier)
    }
    
}
