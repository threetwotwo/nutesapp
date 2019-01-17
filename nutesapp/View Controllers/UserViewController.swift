//
//  UserViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 05/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

//protocol UserViewControllerDelegate: class {
//    func didChangeUser(user: User)
//}

class UserViewController: UIViewController, ListAdapterDataSource, UserHeaderSectionControllerDelegate {
    
    func followButtonPressed(user: User) {
        delegate?.followButtonPressed(user: user)
    }
    

    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - Variables
    var items: [ListDiffable] = []
    var firestore = FirestoreManager.shared
    var user: User?
    var sectionIndex: Int?
    
     var delegate: UserHeaderSectionControllerDelegate? = nil
//    var listener: ListenerRegistration!
//    
    let spinToken = "spinner"
//    var lastSnapshot: DocumentSnapshot?
    var isLoading = false
    var endOfList = false
    
    //MARK: - Adapter
    lazy var adapter: ListAdapter = {
        let adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 1)
        adapter.collectionView = collectionView
        adapter.dataSource = self
//        adapter.scrollViewDelegate = self
        return adapter
    }()
    
    
    //MARK: - IBActions
//    @IBAction func followButtonPressed(_ sender: UIButton) {
//        print("pressed follow button")
//
//        guard let user = user else { return }
//
//        guard user.username != firestore.currentUser.username else {
//            print("Edit profile")
//            return
//        }
//
//
////        guard let user = user,
////            let followed = user.username else {return}
//        let username = user.username
////
//        if user.isFollowing {
//            firestore.unfollowUser(withUsername: username) {
//                self.user?.isFollowing = false
//                self.loadHeader()
//            }
//        } else {
//            firestore.followUser(withUsername: username) {
//                self.user?.isFollowing = true
//                self.loadHeader()
//            }
//        }
//    }
    
    //MARK: - Life Cycle

    fileprivate func loadHeader() {
        
        if !items.isEmpty {
            items.remove(at: 0)
        }
        
        if let user = user {
            items.insert(user, at: 0)
        } else {
            items.insert(firestore.currentUser, at: 0)
            self.user = firestore.currentUser
        }
        self.adapter.reloadData(completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadHeader()
        
        self.isLoading = true
        self.adapter.performUpdates(animated: true)

        firestore.getPostsForUser(username: user!.username, limit: 99) { (posts, lastSnapshot) in
            guard let posts = posts else {return}
            
            self.items.append(contentsOf: posts)
//            if let lastSnapshot = lastSnapshot {
//                self.lastSnapshot = lastSnapshot
//            }
            self.isLoading = false
            self.adapter.performUpdates(animated: true)
        }
    }

    //MARK: - ListAdapterDataSource

    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        var objects = items as [ListDiffable]
        
        if isLoading {
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
                let sectionController = UserHeaderSectionController()
                sectionController.delegate = self
                return sectionController
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
