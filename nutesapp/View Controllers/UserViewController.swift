//
//  UserViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 05/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class UserViewController: UIViewController, ListAdapterDataSource {

    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - IBActions
    @IBAction func followButtonPressed(_ sender: UIButton) {
        print("pressed follow button")
//        guard let user = user,
//            let followed = user.username else {return}
//
//        if user.isFollowing {
//            firestore.unfollowUser(withUsername: followed) {
//                self.user?.isFollowing = false
//                self.reloadHeader()
//            }
//        } else {
//            firestore.followUser(withUsername: followed) {
//                self.user?.isFollowing = true
//                self.reloadHeader()
//            }
//        }
    }
    
    //MARK: - Variables
    var items: [ListDiffable] = []
    var firestore = FirestoreManager.shared
    var user: User?
//    var listener: ListenerRegistration!
//    
    let spinToken = "spinner"
//    var lastSnapshot: DocumentSnapshot?
    var loading = false
    var endOfList = false
    
    //MARK: - Adapter
    lazy var adapter: ListAdapter = {
        let adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 1)
        adapter.collectionView = collectionView
        adapter.dataSource = self
//        adapter.scrollViewDelegate = self
        return adapter
    }()
    
    //MARK: - Life Cycle

    fileprivate func loadHeader() {
    
        if let user = user {
            items.insert(user, at: 0)
        } else {
            items.insert(firestore.currentUser, at: 0)
            self.user = firestore.currentUser
        }
        self.adapter.performUpdates(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadHeader()

        firestore.getPostsForUser(username: user!.username, limit: 99) { (posts, lastSnapshot) in
            guard let posts = posts else {return}
            
            self.items.append(contentsOf: posts)
//            if let lastSnapshot = lastSnapshot {
//                self.lastSnapshot = lastSnapshot
//            }
            self.adapter.performUpdates(animated: true)
        }
    }

    //MARK: - ListAdapterDataSource

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
            switch object {
            case is User:
                return UserHeaderSectionController()
            case is Post:
                return UserImageSectionController()
            default:
                return UserHeaderSectionController()
            }
           
        }
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
}
