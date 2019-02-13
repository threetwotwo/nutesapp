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
    
    //MARK: - Variables
    var items: [ListDiffable] = []
    var firestore = FirestoreManager.shared
    var user: User?
    var sectionIndex: Int?
    
    let spinToken = "spinner"
//    var lastSnapshot: DocumentSnapshot?
    var isLoading = false
    var endOfList = false
    
    //MARK: - Adapter
    lazy var adapter: ListAdapter = {
        let adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 1)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
        return adapter
    }()
    
    //MARK: - Life Cycle

    fileprivate func loadHeader() {
        
        if !items.isEmpty {
            items.remove(at: 0)
        }
        
        if let user = user {
            items.insert(user, at: 0)
        }
        
        title = user?.username
        self.adapter.reloadData(completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isLoading = true
        self.adapter.performUpdates(animated: true)
        
        loadHeader()
        
        guard user != nil else { return }

        firestore.getPosts(username: user!.username, limit: 99) { (posts, lastSnapshot) in
            
            self.items.append(contentsOf: posts)
            if let lastSnapshot = lastSnapshot {
//                self.lastSnapshot = lastSnapshot
            }
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
                return UserHeaderSectionController()
            case is Post:
                return UserBodySectionController()
            default:
                return ListSectionController()
            }
           
        }
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
}

//MARK: - UIScrollViewDelegate

extension UserViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !isLoading && distance < 200 {
            isLoading = true
            adapter.performUpdates(animated: true)
        }
    }
}
