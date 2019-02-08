//
//  DatabaseManager.swift
//  nutesapp
//
//  Created by Gary Piong on 16/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import FirebaseDatabase

class DatabaseManager {
        
    let db = Database.database().reference()
    
    //MARK: - User
    
    func getPostCount(username: String, completion: @escaping (Int)->()) {
        db.child("users").child(username).child("post_count").observeSingleEvent(of: .value) { (snap) in
            let count = snap.value as? Int ?? 0
            completion(count)
        }
    }
    
    func getFollowerCount(username: String, completion: @escaping (Int)->()) {
        db.child("users").child(username).child("follower_count").observeSingleEvent(of: .value) { (snap) in
            let count = snap.value as? Int ?? 0
            completion(count)
        }
    }
    
    func getFollowingCount(username: String, completion: @escaping (Int)->()) {
        db.child("users").child(username).child("following_count").observeSingleEvent(of: .value) { (snap) in
            let count = snap.value as? Int ?? 0
            completion(count)
        }
    }

    
    func getUserURL(username: String, completion: @escaping (String)->()) {
        db.child("users").child(username).child("user_url").observeSingleEvent(of: .value) { (snap) in
            let url = snap.value as? String ?? ""
            completion(url)
        }
    }
    
    func updateUserPic(username: String, url: String, completion: @escaping ()->()) {
        db.child("users/\(username)/user_url").setValue(url) { (error, ref) in
            guard error == nil else {
                print(error?.localizedDescription ?? "Error updating url")
                return
            }
            completion()
        }
    }
    
    //MARK: - Posts

    func getPostLikes(postID: String, completion: @escaping (Int, [Comment])->()) {
        db.child("posts").child(postID).observeSingleEvent(of: .value) { (snap) in
            guard let data = snap.value as? NSDictionary else {
                completion(0,[])
                return
            }
            
            var comments = [Comment]()
            
            let likeCount = data["like_count"] as? Int ?? 0
            let topComments = data["top_comments"] as? [NSDictionary]
            
            for topComment in topComments ?? [] {
                let comment = Comment(username: topComment["username"] as? String ?? "", text: topComment["text"] as? String ?? "", likes: topComment["like_count"] as? Int ?? 0)
                comments.append(comment)
            }
            
            completion(likeCount, comments)
        }
    }
    
    func getLikes(commentID: String, postID: String, completion: @escaping (Int, Int)->()) {
        db.child("comments").child(postID).child(commentID).observeSingleEvent(of: .value) { (snap) in
            guard let data = snap.value as? NSDictionary else {
                completion(0,0)
                return
            }
            let likeCount = data["like_count"] as? Int ?? 0
            let replyCount = data["reply_count"] as? Int ?? 0
            completion(likeCount, replyCount)
        }
    }
    
    //MARK: - Comments

    func getReplyCount(commentID: String, completion: @escaping (Int)->()) {
        db.child("comments").child(commentID).observeSingleEvent(of: .value) { (snap) in
            guard let data = snap.value as? NSDictionary else {
                completion(0)
                return
            }
            let likeCount = data["reply_count"] as? Int ?? 0
            completion(likeCount)
        }
    }
}
