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
            self.viewDidLoad()
            refreshControl.endRefreshing()
        }
    }
    
    
    //MARK: - Variables
    lazy var items = [ListDiffable]()
    
    var firestore = FirestoreManager.shared
    let spinToken = "spinner"
    var lastSnapshots = [String:DocumentSnapshot]()
    var loading = false
    
    //MARK: - Life cycle
    
    fileprivate func loadPosts() {
        //get user's following
        firestore.getFollowedUsers(for: firestore.currentUser.username) { (relationships) in
            for relationship in relationships {
                print(relationship.documentID)
                guard let username = relationship.data()["followed"] as? String else {return}
                print(username)
                self.firestore.getPostsForUser(username: username, limit: 3, lastSnapshot: self.lastSnapshots[username]) { posts, lastSnapshot in
                    guard let posts = posts else {return}
                    for post in posts {
                        
                        self.items.append(post)
                    }
                    if let lastSnapshot = lastSnapshot {
                        self.lastSnapshots[username] = lastSnapshot
                    }
                    self.adapter.performUpdates(animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.addSubview(self.refreshControl)
        //For tab bar delegate function in app delegate to work
        self.tabBarController?.delegate = UIApplication.shared.delegate as? UITabBarControllerDelegate
        loadPosts()
    }
    
    @objc func performUpdates() {
        print("notification for like button!")
        adapter.performUpdates(animated: true, completion: nil)
        
    }
}

//MARK: - List adapter data source

extension FeedViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        var objects = items as [ListDiffable]

        if loading {
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
        if !loading && distance < 200 {
            loading = true
            adapter.performUpdates(animated: true, completion: nil)
            DispatchQueue.global(qos: .default).async {
                // fake background loading task
                DispatchQueue.main.async {
                    self.loading = false
                    self.loadPosts()
                }
            }
        }
    }
}
