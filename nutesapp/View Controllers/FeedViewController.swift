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
    @IBAction func logout(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            print("\(firestore.currentUser.username) logged out!")
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignUpVC") as! SignUpViewController
            self.present(vc, animated: true, completion: nil)
            
        } catch {
            print("Unable to logout")
        }
    }
    
    //MARK: - Adapter
    lazy var adapter: ListAdapter = {
        let updater = ListAdapterUpdater()
        let adapter = ListAdapter(updater: updater, viewController: self, workingRangeSize: 1)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
        return adapter
    }()
    
    //MARK: - Pull to refresh
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControl.Event.valueChanged)
        
        return refreshControl
    }()
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            refreshControl.endRefreshing()
        }
    }
    
    //MARK: - Loading

    func startLoading() {
        loading = true
        performUpdates()
    }
    
    func endLoading() {
        loading = false
        performUpdates()
    }
    
    //MARK: - Variables
    lazy var items = [ListDiffable]()
    
    var observers: [Observer] = Observer.types([.unfollow,.follow])
    var firestore = FirestoreManager.shared
    let spinToken = "spinner"
    var lastSnapshots = [String:DocumentSnapshot]()
    var loading = false
    
    //MARK: - Life cycle
    
    fileprivate func loadPosts(user: String? = nil, completion: (()->())? = nil) {
        
        self.startLoading()

        guard user == nil else {
            firestore.getPosts(username: user!, limit: 3) { (posts, lastSnap) in
                self.items.insert(contentsOf: posts, at: 0)
                self.lastSnapshots[user!] = lastSnap
                self.endLoading()
            }
            return
        }
        //get user's following
        firestore.getFollowedUsers(for: firestore.currentUser.username) { (relationships) in
            
            let dsg = DispatchGroup()

            for relationship in relationships {
                guard let username = relationship.data()["followed"] as? String else {return}
                
                dsg.enter()
                self.firestore.getPosts(username: username, limit: 3, lastSnapshot: self.lastSnapshots[username]) { posts, lastSnapshot in
                    
//                    guard !posts.isEmpty else {
//                        dsg.leave()
//                        completion?()
//                        return
//                    }
                    
                    self.items.append(contentsOf: posts)
                    
                    if let lastSnapshot = lastSnapshot {
                        self.lastSnapshots[username] = lastSnapshot
                    }
                    
                    dsg.leave()
                }
            }
            
            dsg.notify(queue: .main, execute: {
                completion?()
            })
        }
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
        loadPosts{
            self.endLoading()
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
    
    @objc func performUpdates() {
        adapter.performUpdates(animated: true, completion: nil)
    }
}

//MARK: - List adapter data source

extension FeedViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        var objects = items as [ListDiffable]
        
        if loading{
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
        if !loading && distance < 100 {
            loadPosts{
                self.endLoading()
            }
        }
    }
}
