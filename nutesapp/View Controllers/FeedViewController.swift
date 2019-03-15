//
//  FeedViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import IGListKit

class FeedViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - IBActions
    @IBAction func signOut(_ sender: Any) {
        firestore.signOut {
            //present sign up screen modally upon a successful sign out
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignUpVC") as! SignUpViewController
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    //MARK: - Adapter
    lazy var adapter: ListAdapter = {
        let updater = ListAdapterUpdater()
        let adapter = ListAdapter(updater: updater, viewController: self, workingRangeSize: 1)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
        adapter.collectionViewDelegate = self
        return adapter
    }()
    
    //MARK: - Pull to refresh
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        
        return refreshControl
    }()
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
//        loadPosts(user: nil, insertAtTop: true) {
//            self.refreshControl.endRefreshing()
//        }
        
        guard !shouldLoadOnlyOnePost else {
            refreshControl.endRefreshing()
            return
        }
        
        lastSnapshots.removeAll()
        items.removeAll()
        
        loadPosts(user: nil, insertAtTop: false) {
            refreshControl.endRefreshing()
            self.endLoading()
        }
    }
    
    //MARK: - Loading

    func startLoading() {
        isLoading = true
        performUpdates()
    }
    
    func endLoading() {
        isLoading = false
        performUpdates()
    }
    
    @objc func performUpdates() {
        adapter.performUpdates(animated: true, completion: nil)
    }
    
    //MARK: - Variables
    lazy var items = [ListDiffable]()
    
    var observers: [Observer] = Observer.types([.unfollow,.follow])
    var firestore = FirestoreManager.shared
    let spinToken = "spinner"
    var lastSnapshots = [String:DocumentSnapshot]()
    var isLoading = false
    
    var cachedIDs = [String]()
    //false if only need to load one post
    var shouldLoadOnlyOnePost = false
    
    //MARK: - Life cycle
    
    fileprivate func loadPosts(user: String? = nil, insertAtTop: Bool = false, completion: (()->())? = nil) {
        guard !shouldLoadOnlyOnePost else { return }

        self.startLoading()

        //if user is not nil, load posts only for that user
        guard user == nil else {
            firestore.getPosts(uid: user!, limit: 3) { (posts, lastSnap) in
                self.items.insert(contentsOf: posts, at: 0)
                self.lastSnapshots[user!] = lastSnap
                self.endLoading()
            }
            return
        }
        
        firestore.getUnseenPosts(username: firestore.currentUser.username, limit: 10) { (posts, lastSnaps) in
            
            guard !posts.isEmpty else {
                print("unseen posts empty")
                self.firestore.getFollowedUsers(for: self.firestore.currentUser.uid) { (relationships) in
                    
                    let dsg = DispatchGroup()
                    var results = [ListDiffable]()
                    
                    
                    for relationship in relationships.shuffled() {
                        
                        guard let uid = relationship.data()["followed"] as? String else {return}
                        
                        dsg.enter()
                        self.firestore.getPosts(uid: uid, limit: 3, lastSnapshot: self.lastSnapshots[uid]) { posts, lastSnapshot in
                            
                            var filteredPosts = [Post]()
                            
                            for post in posts {
                                if !self.items.contains{($0 as? Post)?.id == post.id} {
                                    filteredPosts.append(post)
                                }
                     
                            }
                            
                            if insertAtTop {
                                results.insert(contentsOf: filteredPosts, at: 0)
                            } else {
                                results.append(contentsOf: filteredPosts)
                            }
                            
                            if let lastSnapshot = lastSnapshot {
                                self.lastSnapshots[uid] = lastSnapshot
                            }
                            
                            dsg.leave()
                        }
                    }
                    
                    dsg.notify(queue: .main, execute: {
                        self.items.append(contentsOf: results.shuffled())
                        completion?()
                    })
                }
                return
            }
            
            self.items.append(contentsOf: posts)
            self.lastSnapshots = lastSnaps!
            print(self.lastSnapshots.keys, posts.map{$0.id})
            completion?()
        }
//        //get user's following
//        firestore.getFollowedUsers(for: firestore.currentUser.username) { (relationships) in
//
//            let dsg = DispatchGroup()
//            var results = [ListDiffable]()
//
//
//            for relationship in relationships.shuffled() {
//
//                guard let username = relationship.data()["followed"] as? String else {return}
//
//                dsg.enter()
//                self.firestore.getPosts(username: username, limit: 3, lastSnapshot: self.lastSnapshots[username]) { posts, lastSnapshot in
//
//                    if insertAtTop {
//                        results.insert(contentsOf: posts, at: 0)
//                    } else {
//                        results.append(contentsOf: posts)
//                    }
//
//                    if let lastSnapshot = lastSnapshot {
//                        self.lastSnapshots[username] = lastSnapshot
//                    }
//
//                    dsg.leave()
//                }
//            }
//
//            dsg.notify(queue: .main, execute: {
//                self.items.append(contentsOf: results.shuffled())
//                completion?()
//            })
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //top activity indicator
        // Add Refresh Control to Table View

        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        //For tab bar delegate function in app delegate to work
        self.tabBarController?.delegate = UIApplication.shared.delegate as? UITabBarControllerDelegate
        
        if !shouldLoadOnlyOnePost {
            loadPosts{
                self.endLoading()
            }
        } else {
            performUpdates()
        }


        self.addObservers(observers: self.observers, selector: #selector(onChange))
    }
    
    @objc func onChange(notification: Notification) {
        
        guard let object = notification.object as? (Observer.ObserverType, Any),
        
        let username = object.1 as? String else {
            return
        }
        
        switch object.0 {
        case .unfollow:
            //remove posts from unfollowed user
            self.items = self.items.filter{ ($0 as? Post)?.username != username }
            performUpdates()
            //remove unfollowed user last snap
            self.lastSnapshots[username] = nil
        case .follow:
            loadPosts(user: username)
        }
    }
    
}

//MARK: - List adapter data source

extension FeedViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        var objects = items as [ListDiffable]
        
        if isLoading{
            objects.append(spinToken as ListDiffable)
        }
        
        return objects
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        if let obj = object as? String, obj == spinToken {
            return spinnerSectionController()
        } else {
            return FeedSectionController()
        }
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }

}

extension FeedViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !isLoading && distance < 100 {
            loadPosts{
                self.endLoading()
            }
        }
    }
}

extension FeedViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let _ = cell as? PostHeaderCell,
        let post = items[indexPath.section] as? Post {
            guard !cachedIDs.contains(post.id) else {return}
            cachedIDs.append(post.id)
//            firestore.setPostAsSeen(postID: post.id)
            print(post.id)
        }
    }
}
