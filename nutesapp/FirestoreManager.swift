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
        db.settings = settings
    }
    
    //MARK: - Presence
    
    func setPostAsSeen(postID: String) {
        db.collection("users")
        .document(currentUser.username)
        .collection("seen_posts")
        .document(postID)
        .setData(["timestamp" : Timestamp()])


        db.collection("users")
        .document(currentUser.username)
        .collection("unseen_posts")
        .document(postID)
        .delete()
    }

    
    //MARK: - Retrieve posts
    
    func getUnseenPosts(username: String, limit: Int, lastSnap: DocumentSnapshot? = nil, completion: @escaping (_ posts:[Post], _ lastSnaps: [String:DocumentSnapshot]?) -> ()) {
        var query: Query
        let user = currentUser.username
        //Pagination
        if lastSnap == nil {
            query = db
                .collection("users")
                .document(username)
                .collection("unseen_posts")
                .order(by: "timestamp", descending: false)
                .limit(to: limit)
        } else {
            query = db
                .collection("users")
                .document(username)
                .collection("unseen_posts")
                .order(by: "timestamp", descending: false)
                .limit(to: limit)
                .start(afterDocument: lastSnap!)
        }
        
        query.getDocuments { (documents, error) in
            guard error == nil,
                let documents = documents?.documents else {
                    print(error?.localizedDescription ?? "Error fetching posts!")
                    return
            }
            var items = [Post]()
            let dsg = DispatchGroup()
            
            var snaps = [String:DocumentSnapshot]()
            
            for document in documents {
                
                let id = document.documentID
                let username = document.get("username") as! String
                var likeCount = 0
                let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue()
                let postUrl = document.get("post_url") as! String
                var userURL = ""
                
                var topComments = [Comment]()
                
                var followedUsernames = [String]()
                var userDidLike = false
                
                snaps[username] = document
                print(snaps.keys, id)
                
                dsg.enter()
                DatabaseManager().getUserURL(username: username, completion: { (url) in
                    userURL = url
                    dsg.leave()
                })
                
                dsg.enter()
                DatabaseManager().getPostLikes(postID: id, completion: { (likes, comments)  in
                    likeCount = likes
                    topComments = comments
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
                
                dsg.notify(queue: .main) {
                    let post = Post(
                        id: id,
                        username: username,
                        timestamp: timestamp!,
                        userURL: userURL,
                        postURL: postUrl,
                        likeCount: likeCount,
                        followedUsernames: followedUsernames,
                        didLike: userDidLike,
                        comments: topComments
                    )
                    items.append(post)
                }
            }
            dsg.notify(queue: .main) {
                completion(items, snaps)
            }
        }
    }
    
    func getPosts(username: String, limit: Int, lastSnapshot: DocumentSnapshot? = nil, completion: @escaping (_ posts:[Post], _ lastSnapshot: DocumentSnapshot?) -> ()) {
        
        var query: Query
        
        //Pagination
        if lastSnapshot == nil {
            query = db
                .collection("posts").whereField("username", isEqualTo: username)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
        } else {
            query = db
                .collection("posts").whereField("username", isEqualTo: username)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .start(afterDocument: lastSnapshot!)
        }
        
        query.getDocuments { (documents, error) in
            guard error == nil,
                let documents = documents?.documents else {
                    print(error?.localizedDescription ?? "Error fetching posts!")
                    return
            }
            var items = [Post]()
            let dsg = DispatchGroup()
            
            for document in documents {
                let id = document.documentID
                let username = document.get("username") as! String
                var likeCount = 0
                let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue()
                let postUrl = document.get("post_url") as! String
                var userURL = ""
                
                var topComments = [Comment]()
                
                var followedUsernames = [String]()
                var userDidLike = false
                
                dsg.enter()
                DatabaseManager().getUserURL(username: username, completion: { (url) in
                    userURL = url
                    dsg.leave()
                })
                
                dsg.enter()
                DatabaseManager().getPostLikes(postID: id, completion: { (likes, comments)  in
                    likeCount = likes
                    topComments = comments
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
                
                dsg.notify(queue: .main) {
                    let post = Post(
                        id: id,
                        username: username,
                        timestamp: timestamp!,
                        userURL: userURL,
                        postURL: postUrl,
                        likeCount: likeCount,
                        followedUsernames: followedUsernames,
                        didLike: userDidLike,
                        comments: topComments
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
    
    //MARK: - Posts
    
    func createPost(imageData: Data) {
        //createdBy
        let username = currentUser.username
        
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
                
                //create and update documents
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    
                    transaction.setData([
                        "like_count": 0,
                        "username" : username,
                        "post_url" : postURL,
                        "timestamp" : timestamp,
                        "top_comments" : NSArray()
                        ], forDocument: postRef)
                    
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
    
    func getLikes(postID: String, limit: Int, lastSnap: DocumentSnapshot? = nil, completion: @escaping(([User])->())) {
        
        let query: Query
        
        if lastSnap == nil {
            query = db.collection("posts")
            .document(postID)
            .collection("likes")
            .limit(to: limit)
        } else {
            query = db.collection("posts")
            .document(postID)
            .collection("likes")
            .limit(to: limit)
            .start(afterDocument: lastSnap!)
        }

        let dsg = DispatchGroup()
        var results = [User]()
        
        query.getDocuments { (snap, error) in
            
            for document in snap?.documents ?? [QueryDocumentSnapshot]() {
                
                let username = document.documentID
        
                dsg.enter()
                self.getUser(username: username, completion: { (user) in
                    results.append(user)
                    dsg.leave()
                })
            }
            
            dsg.notify(queue: .main, execute: {
                completion(results)
            })
        }
        
    }
    
    func getFollowedLikes(postID: String, limit: Int, completion: @escaping (Int, [String]) -> ()) {
        getFollowedUsers(for: currentUser.username) { (documents) in
            
            var usernames = [String]()
            var limitReached = false
            
            let dsg = DispatchGroup()
            
            for document in documents.shuffled() {
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
    
    func comment(comment: Comment, post: Post, text: String, completion: (()->())? = nil) {
        
        let username = currentUser.username
        let timestamp = comment.timestamp
        let commentID = "\(username)_\(timestamp.seconds)"
        
        let postRef = db.collection("posts").document(post.id)
        let commentRef = postRef.collection("comments").document(commentID)
        
        let parentID: Any = comment.parentID == nil ? NSNull() : comment.parentID ?? ""

        db.runTransaction({ (transaction, errorPointer) -> Any? in

            transaction.setData([
                "like_count": 0,
                "parent_id" : parentID,
                "post_id" : post.id,
                "username" : username,
                "text" : text,
                "timestamp" : comment.timestamp
                ], forDocument: commentRef)
            return nil
        }) { (object, error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "Error commenting")
                return
            }
            completion?()
        }
    }
    
    func like(comment: Comment, completion: (()->())? = nil) {
        
        let username = currentUser.username
        let timestamp = FieldValue.serverTimestamp()

        let likeRef = db
            .collection("posts").document(comment.postID)
            .collection("comments").document(comment.id)
            .collection("likes").document(username)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.setData([
                "username" : username,
                "timestamp" : timestamp,
                "text" : comment.text
                ], forDocument: likeRef)
            return nil
        }) { (object, error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "Error commenting")
                return
            }
            completion?()
        }
    }
    
    func unlike(comment: Comment, completion: (()->())? = nil) {
        
        let likeRef = db
            .collection("posts").document(comment.postID)
            .collection("comments").document(comment.id)
            .collection("likes").document(currentUser.username)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.deleteDocument(likeRef)
            return nil
        }) { (object, error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "Error commenting")
                return
            }
            completion?()
        }
    }
    
    func userDidLikeComment(postID: String, commentID: String,  completion: @escaping (Bool)->()) {
        let username = currentUser.username
        let likeRef = db.collection("posts")
            .document(postID)
            .collection("comments")
            .document(commentID)
            .collection("likes")
            .document(username)
        
        likeRef.getDocument { (snapshot, error) in
            guard error == nil, let didLike = snapshot?.exists else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            completion(didLike)
        }
    }
    
    func getReplies(postID: String, parentID: String, limit: Int, after: DocumentSnapshot? = nil, completion: @escaping ([Comment], DocumentSnapshot?) -> ()) {
        
        let query: Query
        
        if after == nil {
            query = db.collection("posts").document(postID).collection("comments").whereField("parent_id", isEqualTo: parentID)
                .limit(to: limit)
        } else {
            query = db.collection("posts").document(postID).collection("comments").whereField("parent_id", isEqualTo: parentID)
                .start(afterDocument: after!)
                .limit(to: limit)
        }

            query.getDocuments { (snapshot, error) in
                
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
                        let timestamp = data["timestamp"] as? Timestamp
                        
                        var commentLikes: Int = 0
                        var commentDidLike = false
                        
                        dsg.enter()
                        self.userDidLikeComment(postID: postID, commentID: document.documentID, completion: { (didLike) in
                            commentDidLike = didLike
                            dsg.leave()
                        })
                        
                        dsg.enter()
                        DatabaseManager().getLikes(commentID: document.documentID, postID: postID, completion: { (likes, replies) in
                            commentLikes = likes
                            dsg.leave()
                        })
                        
                        dsg.notify(queue: .main, execute: {
                            let comment = Comment(parentID: parentID, commentID: document.documentID, postID: postID, username: username, text: text, likes: commentLikes, timestamp: timestamp ?? Timestamp(), didLike: commentDidLike)
                            comments.append(comment)
                        })
                    }
                    dsg.notify(queue: .main, execute: {
                        completion(comments, documents.last)
                    })
                }
        }
    }
    
    
    func getComments(postID: String, limit: Int, after: DocumentSnapshot? = nil, completion: @escaping ([Comment], DocumentSnapshot?)->()) {
        
        let query: Query
        
        if after == nil {
            query = db.collection("posts").document(postID).collection("comments").whereField("parent_id", isEqualTo: NSNull())
                .order(by: "like_count", descending: true)
                .limit(to: limit)
        } else {
            query = db.collection("posts").document(postID).collection("comments").whereField("parent_id", isEqualTo: NSNull())
                .order(by: "like_count", descending: true)
                .start(afterDocument: after!)
                .limit(to: limit)
        }
        
        query.getDocuments { (snapshot, error) in
            
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
                    let timestamp = data["timestamp"] as? Timestamp
                    let commentID = document.documentID
                    var commentDidLike = false
                    var likeCount = 0
                    var replyCount = 0
                    
                    dsg.enter()
                    DatabaseManager().getLikes(commentID: commentID, postID: postID, completion: { (likes, replies)  in
                        likeCount = likes
                        replyCount = replies
                        dsg.leave()
                    })
                    
                    dsg.enter()
                    self.userDidLikeComment(postID: postID, commentID: commentID, completion: { (didLike) in
                        commentDidLike = didLike
                        dsg.leave()
                    })
                    
                    dsg.notify(queue: .main, execute: {
                        let comment = Comment(parentID: nil, commentID: commentID, postID: postID, username: username, text: text, likes: likeCount, timestamp: timestamp ?? Timestamp(), didLike: commentDidLike, replyCount: replyCount)
                        comments.append(comment)
                    })
                }
                
                dsg.notify(queue: .main, execute: {
                    completion(comments, documents.last)
                })
                
            }
        }
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
    
    //MARK: - Get profile pic for username

    func getProfileURL(username: String, completion: @escaping (URL?)->()) {
        self.getUserInfo(username: username) { (data) in
            let url = data["url"] as? URL
            completion(url)
        }
    }
    
    //MARK: - update profile pic
    
    func updateProfile(image: UIImage, completion: @escaping ()->()) {
        //Storage ref
        let imageRef = Storage.storage().reference().child("profiles").child(currentUser.username + ".jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.25) else {return}
        
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            
            guard error == nil else {
                print(error?.localizedDescription ?? "Error putting data")
                return
            }
            
            imageRef.downloadURL(completion: { (url, error) in
                DatabaseManager().updateUserPic(username: self.currentUser.username, url: url?.absoluteString ?? "", completion: {
                    completion()
                })
            })
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
            var followers = 0
            var userUrl = data["url"] as? String ?? ""
            var isFollowingUser: Bool = false
            
            let dsg = DispatchGroup()
            
            if self.currentUser != nil && username != self.currentUser.username {
                dsg.enter()
                self.isFollowing(follower: self.currentUser.username, followed: username, completion: { (isFollowing) in
                    dsg.leave()
                    isFollowingUser = isFollowing
                })
            }
            
            dsg.enter()
            DatabaseManager().getFollowerCount(username: username, completion: { (count) in
                followers = count
                dsg.leave()
            })
            
            dsg.enter()
            DatabaseManager().getUserURL(username: username, completion: { (url) in
                userUrl = url
                dsg.leave()
            })
            
            dsg.notify(queue: .main, execute: {
                let user = User(
                    uid: uid ?? "",
                    fullname: fullname ?? "",
                    email: email ?? "",
                    username: username,
                    url: userUrl,
                    followerCount: followers
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
                    self.defaults.set(encoded, forKey: "savedUsers")
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
            
            let userRef = self.db.collection("users").document(username)
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
             
                transaction.setData([
                    "email" : email,
                    "fullname" : fullname,
                    "username" : username,
                    "timestamp" : FieldValue.serverTimestamp()
                    ], forDocument: userRef)
                
                return nil
            }, completion: { (object, error) in
                if error == nil {
                    self.currentUser = User(uid: uid, fullname: fullname, email: email, username: username, url: "", followerCount: 0)
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
    
    
}



