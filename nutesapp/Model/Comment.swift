//
//  Comment.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

final class Comment: ListDiffable {
    private var identifier: String = UUID().uuidString
    
    let commentID: String
    let parentID: String?
    let postID: String
    let username: String
    let text: String
    let timestamp: Date
    let likes: Int
    let didLike: Bool
    
    init(parentID: String?, commentID: String, postID: String, username: String, text: String, likes: Int, timestamp: Date, didLike: Bool) {
        self.parentID = parentID
        self.commentID = commentID
        self.postID = postID
        self.username = username
        self.text = text
        self.likes = likes
        self.timestamp = timestamp
        self.didLike = didLike
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return (identifier) as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return true
    }
    
}
