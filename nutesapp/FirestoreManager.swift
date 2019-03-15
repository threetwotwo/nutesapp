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
    var currentUserRef: DocumentReference!
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()

    func configureDB() {
        let settings = db.settings
        db.settings = settings
    }
    
    func getChatID(with username: String, completion: @escaping (String)->()) {
        let current = currentUser?.username ?? ""
        let id = current < username ? "\(current)_\(username)" : "\(username)_\(current)"
        let query = db.collection("chats").document(id)
        query.getDocument(completion: { (snap, error) in
            if let chatID = snap?.documentID {
                completion(chatID)
            } else {
                print("chat not found")
            }
        })
    }
    
    //MARK: - Presence
    
    func setPostAsSeen(postID: String) {
        db.collection("users")
        .document(currentUser.uid)
        .collection("seen_posts")
        .document(postID)
        .setData(["timestamp" : Timestamp()])


        db.collection("users")
        .document(currentUser.uid)
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
                let data = document.data()
                let uid = data["uid"] as? String ?? ""
                let username = data["uid"] as? String ?? ""
                var likeCount = 0
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
                let postUrl = data["post_url"] as? String ?? ""
                var userURL = ""
                
                var topComments = [Comment]()
                
                var followedUsernames = [String]()
                var userDidLike = false
                
                snaps[username] = document
                print(snaps.keys, id)
                
                dsg.enter()
                DatabaseManager().getUserURL(uid: username, completion: { (url) in
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
                        uid: uid,
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
    
    func getPost(postID: String, data: [String:Any]) -> Post {
        let id = postID
        let uid = data["uid"] as? String ?? ""
        let username = data["username"] as? String ?? ""
        let likeCount = data["like_count"] as? Int ?? 0
        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        let postUrl = data["post_url"] as? String ?? ""
        let userURL = ""
        
        let post = Post(id: id, uid: uid, username: username, timestamp: timestamp, userURL: userURL, postURL: postUrl, likeCount: likeCount, followedUsernames: [], didLike: false, comments: [])
        
        return post
    }
    
    func getTopPosts(limit: Int, lastSnapshot: DocumentSnapshot? = nil, completion: @escaping (_ posts:[Post], _ lastSnapshot: DocumentSnapshot?) -> ()) {
        var query: Query
        
        //Pagination
        if lastSnapshot == nil {
            query = db
                .collection("posts")
                .order(by: "like_count", descending: true)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
        } else {
            query = db
                .collection("posts")
                .order(by: "like_count", descending: true)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .start(afterDocument: lastSnapshot!)
        }
        
        query.getDocuments { (snap, error) in
            
            guard error == nil,
                let docs = snap?.documents else {
                    print(error?.localizedDescription ?? "Error fetching posts!")
                    return
            }
            
            var posts = [Post]()
            
            for doc in docs {
                let postData = doc.data()
                posts.append(self.getPost(postID: doc.documentID, data: postData))
            }
            
            completion(posts, docs.last)
        }
    }
    
    func getPosts(uid: String, limit: Int, lastSnapshot: DocumentSnapshot? = nil, completion: @escaping (_ posts:[Post], _ lastSnapshot: DocumentSnapshot?) -> ()) {
        
        var query: Query
        
        //Pagination
        if lastSnapshot == nil {
            query = db
                .collection("posts").whereField("uid", isEqualTo: uid)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
        } else {
            query = db
                .collection("posts").whereField("uid", isEqualTo: uid)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .start(afterDocument: lastSnapshot!)
        }
        
        print("queryPath:",query.debugDescription)
        
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
                
                let data = document.data()
                
                let uid = data["uid"] as? String ?? ""
                let username = data["username"] as? String ?? ""
                var likeCount = 0
                let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue()
                let postUrl = document.get("post_url") as? String ?? ""
                var userURL = ""
                
                var topComments = [Comment]()
                
                var followedUsernames = [String]()
                var userDidLike = false
                
                dsg.enter()
                self.getUser(username: username, completion: { (user) in
                    userURL = user.url
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
                        uid: uid,
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
        let uid = currentUser.uid
        let username = currentUser.username
        
        //createdAt
        let timestamp = FieldValue.serverTimestamp()
        
        //firestore doc with auto generated id
        let postRef = self.db.collection("posts").document()

        //unique id which will be used for storage
        let postID = postRef.documentID
        
        //Cloud Storage image ref
        let imageRef = Storage.storage().reference().child(postID)
        //MIME type
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        //put image in storage
        imageRef.putData(imageData, metadata: metaData) { (metadata, error) in
            
            imageRef.downloadURL(completion: { (downloadURL, error) in
                guard error == nil,
                let postURL = downloadURL?.absoluteString else {
                    print(error?.localizedDescription ?? "Error uploading")
                    return
                }
                
                //create and update documents
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    
                    transaction.setData([
                        "like_count": 0,
                        "uid" : uid,
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
        let uid = currentUser.uid
        let username = currentUser.username
        let likeRef = db.collection("posts").document(postID).collection("likes").document(username)
        let data: [String:Any] = [
            "uid" : uid,
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
        
        let postRef = db.collection("posts").document(post.id)
        let commentRef = postRef.collection("comments").document()

        let parentID: Any = comment.parentID == nil ? NSNull() : comment.parentID ?? ""

        db.runTransaction({ (transaction, errorPointer) -> Any? in

            transaction.setData([
                "like_count": 0,
                "parent_id" : parentID,
                "post_id" : post.id,
                "uid" : self.currentUser.uid,
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
        
        let uid = currentUser.uid
        let timestamp = FieldValue.serverTimestamp()

        let likeRef = db
            .collection("posts").document(comment.postID)
            .collection("comments").document(comment.id)
            .collection("likes").document(uid)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.setData([
                "uid" : uid,
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
            .collection("likes").document(currentUser.uid)
        
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
    
    //? 
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
                        let postID = data["post_id"] as? String ?? ""
                        let uid = data["uid"] as? String ?? ""
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
                            let comment = Comment(parentID: parentID, commentID: document.documentID, postID: postID, uid: uid, text: text, likes: commentLikes, timestamp: timestamp ?? Timestamp(), didLike: commentDidLike)
                            comments.append(comment)
                        })
                    }
                    dsg.notify(queue: .main, execute: {
                        completion(comments, documents.last)
                    })
                }
        }
    }
    
    //MARK: - Get comments from a post, paginated if provided a doc snapshot

    func getComments(postID: String, limit: Int, after: DocumentSnapshot? = nil, completion: @escaping ([Comment], DocumentSnapshot?)->()) {
        
        let query: Query
        
        //field "parent_id" == null indicates that we are getting root comments
        //unlike replies in which their "parent_id" field is assigned to the comments that they are replying to
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
                    let postID = data["post_id"] as? String ?? ""
                    let uid = data["uid"] as? String ?? ""
                    let text = data["text"] as? String ?? ""
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
                        let comment = Comment(parentID: nil, commentID: commentID, postID: postID, uid: uid, text: text, likes: likeCount, timestamp: timestamp ?? Timestamp(), didLike: commentDidLike, replyCount: replyCount)
                        comments.append(comment)
                    })
                }
                
                dsg.notify(queue: .main, execute: {
                    completion(comments, documents.last)
                })
                
            }
        }
    }
    
    //MARK: - Get uid from username
    func getUID(username: String, completion: @escaping (String)->()) {
        let query = db.collection("users").whereField("username", isEqualTo: username)
        
        query.getDocuments { (snap, error) in
            guard error == nil,
            let data = snap?.documents.first?.data() else {
                print(error?.localizedDescription ?? "Error getting uid")
                return
            }
            
            let uid = data["uid"] as? String ?? ""
            completion(uid)
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
                let username = data["username"] as? String ?? ""
                completion(username)
            }
        }
    }
    
    //MARK: - Get photo url
    func getPhotoURL(uid: String, completion: @escaping (URL?)->()) {
        db.collection("users").document(uid).getDocument { (snap, error) in
            guard error == nil, let data = snap?.data() else {
                print(error?.localizedDescription ?? "Error getting user doc")
                return
            }
            
            let url = data["photo_url"] as? URL
            
            completion(url)
        }
    }

    func getProfileURL(username: String, completion: @escaping (URL?)->()) {
        self.getUserInfo(username: username) { (data) in
            let url = data["photo_url"] as? URL
            completion(url)
        }
    }
    
    //MARK: - Update photo url
    
    func updateProfile(image: UIImage, completion: @escaping (URL?)->()) {
        //Storage ref
        let imagesRef = Storage.storage().reference().child("profiles")
        let fileName = currentUser.uid
        let imageRef = imagesRef.child(fileName)
        let userRef = db.collection("users").document(self.currentUser.uid)

        //TODO: determine max img size
        guard let imageData = image.jpegData(compressionQuality: 0.25) else {return}
        
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            
            guard error == nil else {
                print(error?.localizedDescription ?? "Error putting data")
                return
            }
            let dsg = DispatchGroup()

            imageRef.downloadURL(completion: { (url, error) in
                
                //Update FIRAuth user's photoURL
                dsg.enter()
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.photoURL = url
                changeRequest?.commitChanges { (error) in
                    if error == nil {
                        print(url?.absoluteString ?? "")
                    }
                    dsg.leave()
                }
                
                //Update Firestore
                dsg.enter()
                //Firestore user ref
                guard let urlString = url?.absoluteString else { return }
                
                userRef.updateData(["photo_url" : urlString], completion: { (error) in
                    print("updateData", urlString)
                    dsg.leave()
                })
                
                //Update RTDB
                dsg.enter()
                DatabaseManager().updateUserPic(uid: self.currentUser.uid, url: url?.absoluteString ?? "", completion: {
                    dsg.leave()
                })
                
                dsg.notify(queue: .main, execute: {
                    completion(url)
                })
            })
        }

    }

    //MARK: - Get a user object
    
    //Parses a user object from the data of a firestore doc
    func getUser(doc: QueryDocumentSnapshot, completion: @escaping (User)->()) {
        let data = doc.data()
        
        let uid = data["uid"] as? String ?? ""
        let username = data["username"] as? String ?? ""
        let fullname = data["fullname"] as? String ?? ""
        let email = data["email"] as? String ?? ""
        var followers = 0
        let photoURL = data["photo_url"] as? String ?? ""
        
        let dsg = DispatchGroup()
        
        //get followers
        dsg.enter()
        DatabaseManager().getFollowerCount(uid: uid, completion: { (count) in
            followers = count
            dsg.leave()
        })
 
        
        dsg.notify(queue: .main, execute: {
            let user = User(
                uid: uid,
                fullname: fullname,
                email: email,
                username: username,
                url: photoURL,
                followerCount: followers
            )
            completion(user)
        })
    }
    
    func getUser(username: String, completion: @escaping (User)->()) {
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { (snap, error) in
            
            guard let document = snap?.documents.first else {
                print("document does not exist")
                return
            }
            
            self.getUser(doc: document, completion: { (user) in
                completion(user)
            })
        }
    }
    
    //MARK: - Get user ref
    func getUserRef(uid: String, completion: @escaping(DocumentReference)->()) {
        db.collection("users").whereField("uid", isEqualTo: uid).getDocuments { (snap, error) in
            guard error == nil,
            let doc = snap?.documents.first else {
                print(error?.localizedDescription ?? "Error getting user ref")
                return
            }
            completion(doc.reference)
        }
    }
    
    //MARK: - Get user data
    func getUserInfo(username: String, completion: @escaping (_ data: [String:Any]) -> ()) {
        db.collection("users").whereField("username", isEqualTo: username).getDocuments  { (snap, error) in
            guard let document = snap?.documents.first else {
                print("Document does not exist")
                return
            }
           
            completion(document.data())
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
        
        let follower = self.currentUser.uid
        let followed = user.uid
        
        db.collection("relationships").document().setData([
            "follower" : follower,
            "followed" : followed,
            "timestamp" : FieldValue.serverTimestamp()
        ]) { error in
            
            guard error == nil else {
                return
            }
            
            //TODO: implement a logical local cache
//            if var savedUsers = self.defaults.array(forKey: "savedUsers") as? [User] {
//                savedUsers.append(user)
//                if let encoded = try? self.encoder.encode(savedUsers) {
//                    self.defaults.set(encoded, forKey: "savedUsers")
//                }
//            }
            completion()
        }
        
    }
    
    func follow(uid: String, completion: @escaping ()->()) {
        let follower = self.currentUser.uid
        db.collection("relationships").document().setData([
            "follower" : follower,
            "followed" : uid,
            "timestamp" : FieldValue.serverTimestamp()
        ]) { error in
            guard error == nil else {
                print("error following user")
                return
            }
            completion()
        }
    }
    
    func unfollow(uid: String, completion: @escaping ()->()) {
        let follower = self.currentUser.uid
        
        let query = db.collection("relationships")
        .whereField("follower", isEqualTo: follower)
        .whereField("followed", isEqualTo: uid)

        query.getDocuments { (snap, error) in
            guard error == nil,
            let doc = snap?.documents.first else {
                print(error?.localizedDescription ?? "Error finding relationship")
                return
            }
            
            doc.reference.delete()
            
            completion()
        }
    }
    
    //MARK: - Get followed users
    func isFollowing(follower: String, followed: String, completion: @escaping (Bool)->()) {
        let query = db.collection("relationships")
            .whereField("follower", isEqualTo: follower)
            .whereField("followed", isEqualTo: followed)
        query.getDocuments { (snap, error) in
            guard error == nil,
            let doc = snap?.documents else {
                print(error?.localizedDescription ?? "Error finding relationships")
                return
            }
            completion(doc.first?.exists ?? false)
        }
    }
    
    func getFollowedUsers(for uid: String, completion: @escaping ([QueryDocumentSnapshot]) -> ()) {
        db.collection("relationships").whereField("follower", isEqualTo: uid).getDocuments { (documents, error) in
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
        
        //FIR Auth create user
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "error in creating user")
                //TODO: UI to show error
                return
            }
            
            guard let email = authResult?.user.email,
                let uid = authResult?.user.uid else { return }
            
            //create user doc using uid as the docID, as opposed to using username which can be changed
            let userRef = self.db.collection("users").document(uid)
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
             
                transaction.setData([
                    "uid" : uid,
                    "email" : email,
                    "fullname" : fullname,
                    "username" : username,
                    "timestamp" : FieldValue.serverTimestamp()
                    ], forDocument: userRef)
                
                return nil
            }, completion: { (object, error) in
                if error == nil {
                    self.currentUser = User(uid: uid, fullname: fullname, email: email, username: username, url: "", followerCount: 0)
//                    self.defaults.set(username, forKey: "username")
                    completion()
                }
            })
            
        }
    }
    
    //Sign in method using username and password
    //TODO: save password method
    func signIn(forUsername username: String, password: String, completion: @escaping () -> ()) {
        //get user data from username
        getUser(username: username) { (user) in
            //FIR sign in using email and password
            Auth.auth().signIn(withEmail: user.email, password: password) { (result, error) in
              
                guard error == nil else {
                    print(error?.localizedDescription ?? "error in logging in")
                    //TODO: UI to show error
                    return
                }
                
                UserDefaultsManager().updateCurrentUser(user: user)
                self.currentUser = user
                completion()
//                self.getUserRef(uid: user.uid, completion: { (ref) in
//                    print(ref.path)
//                    self.currentUserRef = ref
//                    completion()
//                })
            }
            
        }
    }
    
    func signOut(completion: @escaping ()->()) {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            completion()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    
}



