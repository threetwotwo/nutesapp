//
//  FirestoreManager.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import IGListKit
import FirebaseStorage

//Helper class for firebase operations
final class FirestoreManager {
    
    static let shared = FirestoreManager()

    //MARK: - Variables

    var db: Firestore!
    var currentUser: User!
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()

    func configureDB() {
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
    }
    
    //MARK: - Posts
    
    func createPost(imageData: Data) {
        //createdBy
        let username = currentUser.username
        let userURL = currentUser.url
        //createdAt
        let timestamp = FieldValue.serverTimestamp()
        
        //unique id
        let postID = "\(username)_\(Timestamp.init().seconds)"
        
        //Cloud Storage image ref
        let imageRef = Storage.storage().reference().child(postID + ".jpg")
        
        //put image in storage
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            
            imageRef.downloadURL(completion: { (downloadURL, error) in
                guard error == nil,
                let postURL = downloadURL?.absoluteString else {
                    print(error?.localizedDescription ?? "Error uploading")
                    return
                }
                
                let postRef = self.db.collection("posts").document(postID)
                let userRef = self.db.collection("users").document(username)
                
                //create and update documents
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    let userDoc: DocumentSnapshot
                    do {
                        try userDoc = transaction.getDocument(userRef)
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return nil
                    }
                    
                    guard let postCount = userDoc.data()?["post_count"] as? Int else {
                        let error = NSError(
                            domain: "AppErrorDomain",
                            code: -1,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Unable to retrieve posts from snapshot \(userDoc)"
                            ]
                        )
                        errorPointer?.pointee = error
                        return nil
                    }
                    
                    transaction.setData([
                        "username" : username,
                        "user_url" : userURL,
                        "post_url" : postURL,
                        "timestamp" : timestamp,
                        "like_count" : 0
                        ], forDocument: postRef)
                    
                    transaction.updateData(["post_count" : postCount + 1], forDocument: userRef)
                    
                    return nil
                }, completion: { (object, error) in
                    guard error != nil else {
                        print(error?.localizedDescription as Any)
                        return
                    }
                })
            })
        }
        db.runTransaction({ (transaction, errorpointer) -> Any? in
            return nil
        }) { (object, error) in
            guard error != nil else {
                print(error?.localizedDescription as Any)
                return
            }
        }

    }

    
    //check if user liked post
    func didLike(username: String, postID: String, completion: ((Bool)->())? = nil) {
        let likeRef = db.collection("posts").document(postID).collection("likes").document(username)
        likeRef.getDocument { (snap, error) in
            guard error == nil,
            let documentExists = snap?.exists else {
                print(error?.localizedDescription ?? "Error getting document")
                return
            }
            completion?(documentExists)
        }
    }
    
    func didLike(postID: String, completion: ((Bool)->())? = nil) {
        self.didLike(username: currentUser.username, postID: postID) { (didLike) in
            completion?(didLike)
        }
    }
    
    func like(postID: String, completion: @escaping ()->()) {
        let username = currentUser.username
        let likeRef = db.collection("posts").document(postID).collection("likes").document(username)
        let data: [String:Any] = [
            "post_id" : postID,
            "username" : username,
            "timestamp" : FieldValue.serverTimestamp()
        ]
        likeRef.setData(data) { (error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "Error liking post")
                return
            }
            completion()
        }
    }
    
    func unlike(postID: String, completion: @escaping ()->()) {
        let username = currentUser.username

        let likeRef = db.collection("posts").document(postID).collection("likes").document(username)

        likeRef.delete { (error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "Error unliking post")
                return
            }
            completion()
        }
    }
    
   
    //MARK: - Likes
    
    func getFollowedLikes(postID: String, limit: Int, completion: @escaping (Int, [String]) -> ()) {
        getFollowedUsers(for: currentUser.username) { (documents) in
            
            var usernames = [String]()
            var limitReached = false
            
            let dsg = DispatchGroup()
            
            for document in documents {
                dsg.enter()
                
                let username = document.get("followed") as! String
                
                guard !limitReached else {return}
                
                self.db.collection("likes")
                    .whereField("post_id", isEqualTo: postID)
                    .whereField("username", isEqualTo: username).getDocuments(completion: { (documents, error) in
                        
                        if let documents = documents,
                            !limitReached,
                            !documents.isEmpty {
                            usernames.append(username)
                        }
                        
                        if usernames.count == limit {
                            limitReached = true
                        }
                        dsg.leave()
                    })
            }
            dsg.notify(queue: .main, execute: {
                completion(usernames.count, usernames)
            })
            
        }
    }
    
    //MARK: - Comments
    //if parentID is nil then it is a root comment, if not then it's a reply
    func createComment(postID: String, username: String, text: String, parentID: String? = nil) {
        let timestamp = FieldValue.serverTimestamp()
        let commentID = "\(postID)_\(username)\(Timestamp().seconds)"
        let counterRef = db.collection("commentLikesCounters").document(commentID)
        let shardsRef = counterRef.collection("shards")
        let commentRef = db.collection("comments").document(commentID)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                //create counter with 10 shards
                transaction.setData(["numShards": 1], forDocument: counterRef)
                for i in 0..<1 {
                    transaction.setData(["count" : 0], forDocument: shardsRef.document(String(i)))
                }
                transaction.setData([
                    "post_id" : postID,
                    "parent_id" : parentID,
                    "username" : username,
                    "text" : text,
                    "timestamp" : timestamp
                    ], forDocument: commentRef)
                
            } catch let error as NSError {
                errorPointer?.pointee = error
            }
            return nil
        }) { (object, error) in
            // ...
            if error != nil {
                print(error?.localizedDescription)
            }
        }
    }
    
    func getReplies(commentID: String, limit: Int, completion: @escaping ([Comment]) -> ()) {
        db.collection("comments")
            .whereField("parent_id", isEqualTo: commentID)
            .limit(to: limit)
            .getDocuments { (snapshot, error) in
                
                guard error == nil else {
                    return
                }
                
                let dsg = DispatchGroup()
                
                var comments = [Comment]()
                if let documents = snapshot?.documents {
                    
                    for document in documents {
                        
                        let data = document.data()
                        let parentID = data["parent_id"] as? String
                        let postID = data["post_id"] as! String
                        let username = data["username"] as! String
                        let text = data["text"] as! String
                        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
                        let shardsRef = self.db.collection("commentLikesCounters").document(document.documentID)
                        
                        var commentLikes: Int = 0
                        var commentDidLike = false
                        
//                        dsg.enter()
//                        self.getTotalLikes(ref: shardsRef, completion: { (likes) in
//                            commentLikes = likes
//                            dsg.leave()
//                        })
                        
                        dsg.enter()
                        self.userDidLikeComment(postID: postID, commentID: document.documentID, completion: { (didLike) in
                            commentDidLike = didLike
                            dsg.leave()
                        })
                        
                        dsg.notify(queue: .main, execute: {
                            let comment = Comment(parentID: parentID, commentID: document.documentID, postID: postID, username: username, text: text, likes: commentLikes, timestamp: timestamp ?? Date(), didLike: commentDidLike)
                            comments.append(comment)
                        })
                    }
                    dsg.notify(queue: .main, execute: {
                        completion(comments)
                    })
                }
        }
    }
    
    func userDidLikeComment(postID: String, commentID: String,  completion: @escaping (Bool)->()) {
        let username = currentUser.username
        let likeID = "\(commentID)_\(username)"
        let likeRef = db.collection("commentLikes").document(likeID)
        
        likeRef.getDocument { (snapshot, error) in
            guard error == nil, let didLike = snapshot?.exists else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            completion(didLike)
        }
    }
    
    func getComments(postID: String, limit: Int, completion: @escaping ([Comment])->()) {
        db.collection("comments")
            .whereField("post_id", isEqualTo: postID)
            .whereField("parent_id", isEqualTo: NSNull())
            .limit(to: limit)
            .getDocuments { (snapshot, error) in
                
                guard error == nil else {
                    return
                }
                
                let dsg = DispatchGroup()
                
                var comments = [Comment]()
                if let documents = snapshot?.documents {
                    
                    for document in documents {
                        
                        let data = document.data()
                        let postID = data["post_id"] as! String
                        let username = data["username"] as! String
                        let text = data["text"] as! String
                        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
                        let commentID = document.documentID
                        let shardsRef = self.db.collection("commentLikesCounters").document(commentID)
                        print("getcomments = \(commentID)")
                        
                        var commentLikes: Int = 0
                        var commentReplies = [Comment]()
                        var commentDidLike = false
                        
                        dsg.enter()
                        self.getReplies(commentID: document.documentID, limit: 20, completion: { (replies) in
                            commentReplies = replies
                            dsg.leave()
                        })
                    
//                        dsg.enter()
//                        self.getTotalLikes(ref: shardsRef, completion: { (likes) in
//                            commentLikes = likes
//                            dsg.leave()
//                        })
                        
                        dsg.enter()
                        self.userDidLikeComment(postID: postID, commentID: commentID, completion: { (didLike) in
                            commentDidLike = didLike
                            dsg.leave()
                        })
                        
                        dsg.notify(queue: .main, execute: {
                            let comment = Comment(parentID: nil, commentID: commentID, postID: postID, username: username, text: text, likes: commentLikes, timestamp: timestamp ?? Date(), didLike: commentDidLike)
                            comments.append(comment)
                            comments.append(contentsOf: commentReplies)
                        })
                    }
                    dsg.notify(queue: .main, execute: {
                        completion(comments)
                    })
                }
        }
    }
    
    //MARK: - Listeners
    func addUserListener(username: String, completion: @escaping (_ data: [String:Any]) -> ()) -> ListenerRegistration {
        let listener: ListenerRegistration!
        listener = db.collection("users").document(username).addSnapshotListener { (document, error) in
            guard let document = document else {
                print("Document does not exist")
                return
            }
            if let data = document.data() {
                completion(data)
            }
        }
        return listener
    }
    
    //MARK: - Get username from uid
    func getUsername(fromUID uid: String, completion: @escaping (String)->()) {
        db.collection("users").document(uid).getDocument { (document, error) in
            guard let document = document else {
                print("Document does not exist")
                return
            }
            if let data = document.data(){
                let username = data["username"] as! String
                completion(username)
            }
        }
    }
    
    //MARK: - Get a user
    func getUser(username: String, completion: @escaping (User)->()) {
        db.collection("users").document(username).getDocument { (document, error) in
            
            guard let document = document,
            let data = document.data() else {
                print("document does not exist")
                return
            }
            
            let uid = data["uid"] as? String
            let fullname = data["fullname"] as? String
            let email = data["email"] as? String
            let posts = data["post_count"] as? Int
            let followers = data["follower_count"] as? Int
            let following = data["following_count"] as? Int
            let url = data["url"] as? String
            var isFollowingUser: Bool = false
            
            let dsg = DispatchGroup()
            
            if self.currentUser != nil && username != self.currentUser.username {
                dsg.enter()
                self.isFollowing(follower: self.currentUser.username, followed: username, completion: { (isFollowing) in
                    dsg.leave()
                    isFollowingUser = isFollowing
                })
            }
            
            dsg.notify(queue: .main, execute: {
                let user = User(
                    uid: uid ?? "",
                    fullname: fullname ?? "",
                    email: email ?? "",
                    username: username,
                    postCount: posts ?? 0,
                    followerCount: followers ?? 0,
                    followingCount: following ?? 0,
                    isFollowing: isFollowingUser,
                    url: url ?? ""
                )
                completion(user)
            })
        }
    }
    
    //MARK: - Get a user's info
    func getUserInfo(username: String, completion: @escaping (_ data: [String:Any]) -> ()) {
        db.collection("users").document(username).getDocument { (document, error) in
            guard let document = document else {
                print("Document does not exist")
                return
            }
            if let data = document.data() {
                completion(data)
            }
        }
    }
    
    //MARK: - Observe changes for user
    func observeUser(uid: String, completion: @escaping (_ data: [String:Any]) -> ()) {
        db.collection("users").document(uid).addSnapshotListener { (document, error) in
            guard let document = document else {
                print("Document does not exist")
                return
            }
            if let data = document.data() {
                completion(data)
            }
        }
    }
    
    
    //MARK: - Follow/Unfollow
    func follow(user: User, completion: @escaping ()->()) {
        
        let follower = self.currentUser.username
        let followed = user.username
        
        db.collection("relationships").document("\(follower)_\(followed)").setData([
            "follower" : follower,
            "followed" : followed,
            "timestamp" : FieldValue.serverTimestamp()
        ]) { error in
            
            guard error == nil else {
                return
            }
            
            if var savedUsers = self.defaults.array(forKey: "savedUsers") as? [User] {
                savedUsers.append(user)
                if let encoded = try? self.encoder.encode(savedUsers) {
                    let defaults = UserDefaults.standard
                    defaults.set(encoded, forKey: "savedUsers")
                }
            }
            
        }
        
    }
    
    func followUser(withUsername followed: String, completion: @escaping ()->()) {
        let follower = self.currentUser.username
        db.collection("relationships").document("\(follower)_\(followed)").setData([
            "follower" : follower,
            "followed" : followed,
            "timestamp" : FieldValue.serverTimestamp()
        ]) { error in
            guard error == nil else {
                print("error following user")
                return
            }
            completion()
        }
    }
    
    func unfollowUser(withUsername followed: String, completion: @escaping ()->()) {
        let follower = self.currentUser.username
        db.collection("relationships").document("\(follower)_\(followed)").delete { (error) in
            guard error == nil else {
                print("error unfollowing user")
                return
            }
            completion()
        }
    }
    
    //MARK: - Get followed users
    func isFollowing(follower: String, followed: String, completion: @escaping (Bool)->()) {
        let relationshipID = follower + "_" + followed
        db.collection("relationships").document(relationshipID).getDocument { (document, error) in
            if let document = document {
                completion(document.exists)
            }
        }
    }
    
    func getFollowedUsers(for username: String, completion: @escaping ([QueryDocumentSnapshot]) -> ()) {
        db.collection("relationships").whereField("follower", isEqualTo: username).getDocuments { (documents, error) in
            guard error == nil,
                let documents = documents?.documents else {
                    print(error?.localizedDescription ?? "Error finding followed users")
                    return
            }
            completion(documents)
        }
    }
    
    //MARK: - Login/Signup
    
    func usernameExists(_ username: String, completion: @escaping (Bool)->()) {
        db.collection("users").document(username).getDocument { (snap, error) in
            guard error == nil, let document = snap else {
                print(error?.localizedDescription ?? "Error finding user document")
                return
            }
            completion(document.exists)
        }
    }
    
    func createUser(withEmail email: String, fullname:String, username: String, password: String, completion: @escaping () -> ()) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "error in creating user")
                return
            }
            
            guard let email = authResult?.user.email,
                let uid = Auth.auth().currentUser?.uid else { return }
            
//            let usernameRef = self.db.collection("usernames").document(username)
            let userRef = self.db.collection("users").document(username)
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
//                transaction.setData([
//                    "uid" : uid,
//                    "email" : email
//                    ], forDocument: usernameRef)
//                
                transaction.setData([
                    "email" : email,
                    "fullname" : fullname,
                    "username" : username,
                    "timestamp" : FieldValue.serverTimestamp(),
                    "post_count" : 0,
                    "follower_count" : 0,
                    "following_count" : 0
                    ], forDocument: userRef)
                
                return nil
            }, completion: { (object, error) in
                if error == nil {
                    self.currentUser = User(uid: uid, fullname: fullname, username: username)
                    self.defaults.set(username, forKey: "username")
                    completion()
                }
            })
            
        }
    }
    
    func signIn(forUsername username: String, password: String, completion: @escaping () -> ()) {
        
        getUser(username: username) { (user) in

            Auth.auth().signIn(withEmail: user.email, password: password) { (result, error) in
              
                guard error == nil else {
                    print(error?.localizedDescription ?? "error in logging in")
                    return
                }
                
                UserDefaultsManager().updateCurrentUser(user: user)
                self.currentUser = user
                completion()
            }
        }
    }
    
    //MARK: - Retrieve posts
    func getPostsForUser(username: String, limit: Int, lastSnapshot: DocumentSnapshot? = nil, completion: @escaping (_ posts:[ListDiffable]?, _ lastSnapshot: DocumentSnapshot?) -> ()) {
        
        var query: Query!
        
        //Pagination
        if lastSnapshot == nil {
            query = db.collection("posts").whereField("username", isEqualTo: username).order(by: "timestamp", descending: true).limit(to: limit)
        } else {
            query = db.collection("posts").whereField("username", isEqualTo: username).order(by: "timestamp", descending: true).start(afterDocument: lastSnapshot!).limit(to: limit)
        }
        
        query.getDocuments { (documents, error) in
            guard error == nil,
                let documents = documents?.documents else {
                    print(error?.localizedDescription ?? "Error fetching posts!")
                    return
            }
            var items = [ListDiffable]()
            let dsg = DispatchGroup()
            
            for document in documents {
                let id = document.documentID
                let username = document.get("username") as! String
                var likeCount = 0
                let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue()
                let postUrl = document.get("post_url") as! String
                
                var followedUsernames = [String]()
                var userDidLike = false
                var postComments = [Comment]()
                
                dsg.enter()
                DatabaseManager().getPostLikes(postID: id, completion: { (likes) in
                    likeCount = likes
                    dsg.leave()
                })
                
                dsg.enter()
                self.getFollowedLikes(postID: id, limit: 2, completion: { (int, usernames) in
                    followedUsernames = usernames
                    dsg.leave()
                })
                
                dsg.enter()
                self.didLike(postID: id, completion: { (didLike) in
                    userDidLike = didLike
                    dsg.leave()
                })
                
                dsg.enter()
                self.getComments(postID: id, limit: 20, completion: { (comments) in
                    postComments = comments
                    dsg.leave()
                })
                
                dsg.notify(queue: .main) {
                    let post = Post(
                        id: id,
                        username: username,
                        timestamp: timestamp!,
                        userURL: "",
                        postURL: postUrl,
                        likeCount: likeCount,
                        followedUsernames: followedUsernames,
                        didLike: userDidLike,
                        comments: postComments
                    )
                    items.append(post)
                }
            }
            dsg.notify(queue: .main) {
                
                let lastSnapshot = documents.last
                completion(items, lastSnapshot)
            }
        }
    }
    
}



