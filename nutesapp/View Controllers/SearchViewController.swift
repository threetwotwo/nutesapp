//
//  SearchViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 05/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class SearchViewController: UIViewController, ListAdapterDataSource {
    
    //MARK: - IBOutlets

    @IBOutlet weak var collectionView: UICollectionView!
    var searchBar: UISearchBar!
    
    //MARK: - Variables
    
    var items: [ListDiffable] = []
    var firestore = FirestoreManager.shared
    
    let spinToken = "spinner"
    //    var lastSnapshot: DocumentSnapshot?∂
    var isLoading = false
    
    var postID: String?
    
    //MARK: - Adapter
    lazy var adapter: ListAdapter = {
        let updater = ListAdapterUpdater()
        let adapter = ListAdapter(updater: updater, viewController: self, workingRangeSize: 1)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        //        adapter.scrollViewDelegate = self
        return adapter
    }()
    
    //MARK: - Life Cycle

    fileprivate func getAllUsers(postID: String? = nil) {
        if postID == nil {
            firestore.db.collection("users").getDocuments { (documents, error) in
                guard error == nil,
                    let documents = documents?.documents else {
                        print(error?.localizedDescription ?? "Error getting users")
                        return
                }
        
                for document in documents {
                    let username = document.documentID
                    self.firestore.getUser(username: username, completion: { (user) in
                        self.items.append(user)
                        self.adapter.performUpdates(animated: true)
                    })
                    self.isLoading = false
                }
            }
        } else {
            firestore.getLikes(postID: postID!, limit: 10) { (users) in
                self.items.append(contentsOf: users)
                self.isLoading = false
                self.adapter.performUpdates(animated: true)
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //place search bar in nav bar
        searchBar = UISearchBar()
        searchBar.sizeToFit()
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor.black
        searchBar.placeholder = "Search"
        navigationItem.titleView = searchBar
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): UIColor.black], for: .normal)

        //[DEBUG] Load all users from db
        self.isLoading = true
        self.adapter.performUpdates(animated: true)
        searchBar.delegate = self
        
        getAllUsers(postID: self.postID)
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
            return SearchSectionController()
        }
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print("touches began")
//        self.searchBar.endEditing(true)
//    }
    
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchBarSearchButtonClicked")
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("searchBarCancelButtonClicked")
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        guard !searchText.isEmpty else {
            items.removeAll()
            getAllUsers()
            return
        }
        firestore.getUser(username: searchText.lowercased()) { (user) in
            self.items.removeAll()
            self.items = [user]
            self.adapter.performUpdates(animated: true, completion: nil)
        }
    }
}
