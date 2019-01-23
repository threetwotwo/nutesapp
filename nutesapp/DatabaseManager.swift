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
    
    func getPostLikes(postID: String, completion: @escaping (Int)->()) {
        db.child("posts").child(postID).observeSingleEvent(of: .value) { (snap) in
            guard let data = snap.value as? NSDictionary else {
                completion(0)
                return
            }
            let likeCount = data["like_count"] as? Int ?? 0
            completion(likeCount)
        }
    }
    
    func getLikes(commentID: String, completion: @escaping (Int)->()) {
        db.child("comments").child(commentID).observeSingleEvent(of: .value) { (snap) in
            guard let data = snap.value as? NSDictionary else {
                completion(0)
                return
            }
            let likeCount = data["like_count"] as? Int ?? 0
            completion(likeCount)
        }
    }
}
