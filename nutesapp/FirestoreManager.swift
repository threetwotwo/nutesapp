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
    
    var db: Firestore!
    var currentUser: User!
    let defaults = UserDefaults.standard
    
    func configureDB() {
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
    }
    
    //MARK: - Posts
    
    func createPost(imageData: Data) {
        let username = currentUser.username
        let timestamp = FieldValue.serverTimestamp()
        
        //unique id
        let postID = "\(username)\(Timestamp.init().seconds)"
        
        //Cloud Storage image ref
        let imageRef = Storage.storage().reference().child(postID + ".jpg")
        
        //post likes counter
        let counterRef = db.collection("postLikesCounters").document(postID)
        createPostLikesCounter(ref: counterRef, numShards: currentUser.followers + 1)
        
        //put image in storage
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            
            imageRef.downloadURL(completion: { (downloadURL, error) in
                guard error == nil,
                let imageUrl = downloadURL?.absoluteString else {
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
                    
                    guard let oldPosts = userDoc.data()?["posts"] as? Int else {
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
                        "uid" : self.currentUser.uid,
                        "username" : username,
                        "imageURL" : imageUrl,
                        "timestamp" : timestamp,
                        "likes" : 0
                        ], forDocument: postRef)
                    
                    transaction.updateData(["posts" : oldPosts + 1], forDocument: userRef)
                    
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
    
    func createPostLikesCounter(ref: DocumentReference, numShards: Int) {
        ref.setData(["numShards": numShards]){ (err) in
            for i in 0..<numShards {
                ref.collection("shards").document(String(i)).setData(["count": 0])
            }
        }
    }
    
    //check if user liked post
    func userDidLikePost(username: String, postID: String, completion: @escaping (Bool)->()) {
        let userRef = db.collection("postLikes")
            .whereField("postID", isEqualTo: postID)
            .whereField("username", isEqualTo: username)
        userRef.getDocuments { (documents, error) in
            guard error == nil,
                let documents = documents else {
                    print(error?.localizedDescription ?? "error checking like")
                    return
            }
            let didLike = !documents.isEmpty
            completion(didLike)
        }
    }
    
    func incrementPostLikesCounter(postID: String, numShards: Int, completion: @escaping (Bool)->()) {
        // Select a shard of the counter at random
        let ref = db.collection("postLikesCounters").document(postID)
        let shardId = Int.random(in: 0..<numShards)
        let shardRef = ref.collection("shards").document(String(shardId))
        
        let username = currentUser.username
        
        let likeRef = db.collection("postLikes").document("\(postID)_\(username)")
        
        // Update count in a transaction
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                let shardData = try transaction.getDocument(shardRef).data() ?? [:]
                let shardCount = shardData["count"] as! Int
                transaction.updateData([
                    "count": shardCount + 1
                    ], forDocument: shardRef)
                
                let timestamp = FieldValue.serverTimestamp()
                
                transaction.setData([
                    "postID" : postID,
                    "username"    : username,
                    "timestamp" : timestamp
                    ], forDocument: likeRef)
                
            } catch {
                // Error getting shard data
                // ...
            }
            return nil
        }) { (object, error) in
            // ...
            if error != nil {
                print("increased \(0)")
                completion(false)
            } else {
                print("increased \(1)")
                completion(true)
            }
        }
    }
    
    func decrementPostLikesCounter(postID: String, numShards: Int, completion: @escaping (Bool)->()) {
        // Select a shard of the counter at random
        let ref = db.collection("postLikesCounter").document(postID)
        let shardId = Int.random(in: 0..<numShards)
        let shardRef = ref.collection("shards").document(String(shardId))
        
        let username = currentUser.username
        
        let likeRef = db.collection("postLikes").document("\(postID)_\(username)")
        
        // Update count in a transaction
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                let shardData = try transaction.getDocument(shardRef).data() ?? [:]
                let shardCount = shardData["count"] as! Int
                transaction.updateData(["count": shardCount - 1], forDocument: shardRef)
                transaction.deleteDocument(likeRef)
            } catch {
                // Error getting shard data
                // ...
            }
            
            return nil
        }) { (object, error) in
            // ...
            if error != nil {
                print("decreased \(0)")
                completion(false)
            } else {
                print("decreased \(1)")
                completion(true)
            }
        }
    }
   
    //MARK: - Likes

    func getTotalLikes(ref: DocumentReference, completion: @escaping (Int) -> ()) {
        ref.collection("shards").getDocuments() { (querySnapshot, err) in
            var totalCount = 0
            if err != nil {
                // Error getting shards
                // ...
            } else {
                for document in querySnapshot!.documents {
                    if let count = document.data()["count"] as? Int{
                        totalCount += count
                    }
                }
            }
            completion(totalCount)
        }
    }
    
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
                    .whereField("postID", isEqualTo: postID)
                    .whereField("username", isEqualTo: username).getDocuments(completion: { (documents, error) in
                        
                        if let documents = documents,
                            !limitReached,
                            !documents.isEmpty {
                            usernames.append(username)
                        }
                        
                        if usernames.count == limit {
                            print("reached limit \(usernames.count)")
                            limitReached = true
                        }
                        dsg.leave()
                    })
            }
            dsg.notify(queue: .main, execute: {
                completion(usernames.count, usernames)
                print("usernames = \(usernames)")
                
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
                    "postID" : postID,
                    "parentID" : parentID,
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
            .whereField("parentID", isEqualTo: commentID)
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
                        let parentID = data["parentID"] as? String
                        let postID = data["postID"] as! String
                        let username = data["username"] as! String
                        let text = data["text"] as! String
                        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
                        let shardsRef = self.db.collection("commentLikesCounters").document(document.documentID)
                        
                        var commentLikes: Int = 0
                        var commentDidLike = false
                        
                        dsg.enter()
                        self.getTotalLikes(ref: shardsRef, completion: { (likes) in
                            commentLikes = likes
                            dsg.leave()
                        })
                        
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
    
    func incrementCommentLikesCounter(postID: String, commentID: String) {
        let username = currentUser.username
        let counterID = "\(postID)_\(commentID)"
        let ref = db.collection("commentLikesCounters").document(commentID)
        print(ref.documentID)
        let shardId = Int.random(in: 0..<1)
        let shardRef = ref.collection("shards").document(String(shardId))
        
        let likeID = "\(commentID)_\(username)"
        print(likeID)
        let likeRef = db.collection("commentLikes").document(likeID)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                //                let shardData = try transaction.getDocument(shardRef).data() ?? [:]
                //                let shardCount = shardData["count"] as! Int
                //                transaction.updateData(["count": shardCount + 1], forDocument: shardRef)
                //
                let shardCount = try transaction.getDocument(shardRef).get("count") as! Int
                transaction.updateData(["count": shardCount + 1], forDocument: shardRef)
                
                let timestamp = FieldValue.serverTimestamp()
                
                transaction.setData([
                    "postID" : postID,
                    "commentID" : commentID,
                    "username"    : username,
                    "timestamp" : timestamp
                    ], forDocument: likeRef)
            }  catch let error as NSError {
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
    
    func decrementCommentLikesCounter(postID: String, commentID: String) {
        let username = currentUser.username
        let counterID = "\(postID)_\(commentID)"
        let ref = db.collection("commentLikesCounters").document(commentID)
        
        let shardId = Int(arc4random_uniform(UInt32(1)))
        let shardRef = ref.collection("shards").document(String(shardId))
        
        let likeID = "\(commentID    )_\(username)"
        let likeRef = db.collection("commentLikes").document(likeID)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                let shardData = try transaction.getDocument(shardRef).data() ?? [:]
                let shardCount = shardData["count"] as! Int
                transaction.updateData(["count": shardCount - 1], forDocument: shardRef)
                
                
                transaction.deleteDocument(likeRef)
                
            }  catch let error as NSError {
                errorPointer?.pointee = error
            }
            return nil
            
        }) { (object, error) in
            // ...
            if error != nil {
                print(error?.localizedDescription ?? "")
            }
        }
    }

    
    func getComments(postID: String, limit: Int, completion: @escaping ([Comment])->()) {
        db.collection("comments")
            .whereField("postID", isEqualTo: postID)
            .whereField("parentID", isEqualTo: NSNull())
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
                        let postID = data["postID"] as! String
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
                        
                        dsg.enter()
                        self.getTotalLikes(ref: shardsRef, completion: { (likes) in
                            commentLikes = likes
                            dsg.leave()
                        })
                        
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
    func followUser(withUsername followed: String, completion: @escaping ()->()) {
        let follower = self.currentUser.username
        db.collection("relationships").document("\(follower)_\(followed)").setData([
            "follower" : follower,
            "followed" : followed,
            "timestamp" : FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added")
                completion()
            }
        }
    }
    
    func unfollowUser(withUsername followed: String, completion: @escaping ()->()) {
        let follower = self.currentUser.username
        db.collection("relationships").document("\(follower)_\(followed)").delete { (error) in
            guard error == nil else {
                print("error deleting document")
                return
            }
            completion()
        }
    }
    
    //MARK: - Get followed users
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
    func createUser(withEmail email: String, fullname:String, username: String, password: String, completion: @escaping () -> ()) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "error in creating user")
                return
            }
            
            guard let email = authResult?.user.email,
                let uid = Auth.auth().currentUser?.uid else { return }
            
            let usernameRef = self.db.collection("usernames").document(username)
            let userRef = self.db.collection("users").document(username)
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                transaction.setData([
                    "uid" : uid,
                    "email" : email
                    ], forDocument: usernameRef)
                
                transaction.setData([
                    "email" : email,
                    "fullname" : fullname,
                    "username" : username,
                    "timestamp" : FieldValue.serverTimestamp(),
                    "posts" : 0,
                    "followers" : 0,
                    "following" : 0
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
        getUserInfo(username: username) { (data) in
            let uid = data["uid"] as? String
            let fullname = data["fullname"] as? String
            let email = data["email"] as? String
            let posts = data["posts"] as? Int
            let followers = data["followers"] as? Int
            let following = data["following"] as? Int
            let imageUrl = data["imageUrl"] as? String
            
            Auth.auth().signIn(withEmail: email ?? "" , password: password) { (result, error) in
              
                guard error == nil else {
                    print(error?.localizedDescription ?? "error in logging in")
                    return
                }
                
                self.currentUser = User(
                    uid: uid ?? "",
                    fullname: fullname ?? "",
                    email: email ?? "",
                    username: username,
                    posts: posts ?? 0,
                    followers: followers ?? 0,
                    following: following ?? 0,
                    isFollowing: false,
                    imageUrl: imageUrl ?? ""
                )
                self.defaults.set(uid, forKey: "uid")
                self.defaults.set(fullname, forKey: "fullname")
                self.defaults.set(email, forKey: "email")
                self.defaults.set(username, forKey: "username")
                self.defaults.set(posts, forKey: "posts")
                self.defaults.set(followers, forKey: "followers")
                self.defaults.set(following, forKey: "following")
                self.defaults.set(imageUrl, forKey: "imageUrl")
                
                completion()
            }
        }
//        self.db.collection("usernames").document(username).getDocument { (document, error) in
//            guard error == nil,
//                let document = document,
//                let uid = document.get("uid") as? String,
//                let fullname = document.get("fullname") as? String,
//                let email = document.get("email") as? String else {return}
//
//            Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
//                guard error == nil else {
//                    print(error?.localizedDescription ?? "error in logging in")
//                    return
//                }
//                self.currentUser = User(uid: uid, fullname: fullname, username: username)
//                self.defaults.set(username, forKey: "username")
//                self.defaults.set(fullname, forKey: "fullname")
//                completion()
//            }
//        }
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
            let dispatchGroup = DispatchGroup()
            
            for document in documents {
                let id = document.documentID
                let username = document.get("username") as! String
                let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue()
                let imageURL = document.get("imageURL") as! String
                
                var postLikes: Int = 0
                var followedUsernames = [String]()
                var userDidLike = false
                var postComments = [Comment]()
                
                dispatchGroup.enter()
                let likeCounter = self.db.collection("postLikesCounters").document(id)
                self.getTotalLikes(ref: likeCounter, completion: { (likes) in
                    postLikes = likes
                    dispatchGroup.leave()
                })
                
                dispatchGroup.enter()
                self.getFollowedLikes(postID: id, limit: 2, completion: { (int, usernames) in
                    followedUsernames = usernames
                    dispatchGroup.leave()
                })
                
                dispatchGroup.enter()
                self.userDidLikePost(username: self.currentUser.username, postID: id, completion: { (didLike) in
                    userDidLike = didLike
                    dispatchGroup.leave()
                })
                
                dispatchGroup.enter()
                self.getComments(postID: id, limit: 20, completion: { (comments) in
                    postComments = comments
                    dispatchGroup.leave()
                })
                
                dispatchGroup.notify(queue: .main) {
                    let post = Post(
                        id: id,
                        username: username,
                        timestamp: timestamp!,
                        imageURL: URL(string: imageURL)!,
                        likes: postLikes,
                        followedUsernames: followedUsernames,
                        didLike: userDidLike,
                        comments: postComments
                    )
                    items.append(post)
                }
            }
            dispatchGroup.notify(queue: .main) {
                
                let lastSnapshot = documents.last
                completion(items, lastSnapshot)
            }
        }
    }
    
}



