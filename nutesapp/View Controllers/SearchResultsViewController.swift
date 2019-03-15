//
//  SearchResultsViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 05/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class SearchResultsViewController: UIViewController, ListAdapterDataSource {
    
    //MARK: - IBOutlets

    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - Variables
    
    //navigation controller of searchFeedVC, used to push to userVC
    var navController: UINavigationController?
    
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

    func getAllUsers(postID: String? = nil) {
        if postID == nil {
            firestore.db.collection("users").getDocuments { (documents, error) in
                guard error == nil,
                    let documents = documents?.documents else {
                        print(error?.localizedDescription ?? "Error getting users")
                        return
                }
        
                for document in documents {
                    let data = document.data()
                    let username = data["username"] ?? ""
                    self.firestore.getUser(username: username as! String, completion: { (user) in
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
        
    
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): UIColor.black], for: .normal)

        //[DEBUG] Load all users from db
        self.isLoading = true
        self.adapter.performUpdates(animated: true)
        
        getAllUsers(postID: self.postID)
    }
    
    override func viewDidAppear(_ animated: Bool) {

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

//extension SearchResultsViewController: UISearchControllerDelegate {
//    
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        print("searchBarSearchButtonClicked")
//        searchBar.resignFirstResponder()
//    }
//    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        print("searchBarCancelButtonClicked")
//        searchBar.text = ""
//        searchBar.resignFirstResponder()
//    }
//    
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        print(searchText)
//        guard !searchText.isEmpty else {
//            items.removeAll()
//            getAllUsers()
//            return
//        }
//        firestore.getUser(username: searchText.lowercased()) { (user) in
//            self.items.removeAll()
//            self.items = [user]
//            self.adapter.performUpdates(animated: true, completion: nil)
//        }
//    }
//}


extension SearchResultsViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        // TODO
    }
}
