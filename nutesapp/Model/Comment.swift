//
//  Comment.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//
import Firebase
import Foundation
import IGListKit

final class Comment: ListDiffable {
    
    let id: String
    let parentID: String?
    let postID: String
    let uid: String
    let text: String
    let timestamp: Timestamp
    let likes: Int
    let didLike: Bool
    let replyCount: Int
    
    init(parentID: String?, commentID: String, postID: String, uid: String, text: String, likes: Int, timestamp: Timestamp, didLike: Bool, replyCount: Int = 0) {
        self.parentID = parentID
        self.id = commentID
        self.postID = postID
        self.uid = uid
        self.text = text
        self.likes = likes
        self.timestamp = timestamp
        self.didLike = didLike
        self.replyCount = replyCount
    }
    
    convenience init(uid: String, text: String, likes: Int) {
        self.init(parentID: "", commentID: "", postID: "", uid: uid, text: text, likes: likes, timestamp: Timestamp(), didLike: false)
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return (id) as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? Comment else { return false }
        return (self.id) == (object.id)
    }
    
    static func order(comments: [Comment]) -> [ListDiffable] {
        
        var results = [ListDiffable]()
        
        let rootComments = comments.filter{ $0.parentID == nil }
        
        for comment in rootComments {
            results.append(comment)
            
            //append view more if comment has replies
            if comment.replyCount > 0 {
                results.append(ViewMore(comment: comment, type: .root, count: comment.replyCount))
            }
//            let replies = comments.filter{ $0.parentID == comment.id }
//            for reply in replies {
//                results.append(reply)
//                results.append(ViewMore(comment: comment, type: .reply, count: comment.replyCount))
//                let subreplies = comments.filter{ $0.parentID == reply.id }
//                results.append(contentsOf: subreplies)
//            }
        }
        
        return results
    }
}
