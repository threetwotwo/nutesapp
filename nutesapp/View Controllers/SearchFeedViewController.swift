//
//  SearchFeedViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 18/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit
import FirebaseFirestore
import collection_view_layouts

class SearchFeedViewController: UIViewController {
    
    //MARK: - IBOutlets

    @IBOutlet weak var collectionView: UICollectionView!

    //MARK: - Variables

    var searchController: UISearchController!
    let resultsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Identifier.storyboard.searchresultsVC) as! SearchResultsViewController

    let firestore = FirestoreManager.shared
    let spinToken = "spinner"
    var lastSnapshots = [String:DocumentSnapshot]()
    var loading = false
    
    var cachedIDs = [String]()
    //false if only need to load one post
    var shouldLoadMore = true
    
    var items = [ListDiffable]()
    
    //MARK: - Adapter
    lazy var adapter: ListAdapter = {
        let updater = ListAdapterUpdater()
        let adapter = ListAdapter(updater: updater, viewController: self, workingRangeSize: 1)
        adapter.collectionView = collectionView
//        adapter.dataSource = self
//        adapter.scrollViewDelegate = self
//        adapter.collectionViewDelegate = self
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
        
        guard shouldLoadMore else {
            refreshControl.endRefreshing()
            return
        }
        
        lastSnapshots.removeAll()
        items.removeAll()
        
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
    
    @objc func performUpdates() {
        adapter.performUpdates(animated: true, completion: nil)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpSearchController()
        
        let layout = InstagramStyleFlowLayout()
        layout.delegate = self
        collectionView.setCollectionViewLayout(layout, animated: true)

        collectionView.dataSource = self

    }
    
    //MARK: - Set up search controller

    func setUpSearchController() {
        resultsVC.navController = self.navigationController
        
        //place search bar in nav bar
        searchController = UISearchController(searchResultsController: resultsVC)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.searchBar.tintColor = UIColor.black
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.autocapitalizationType = .none

        navigationItem.searchController = searchController
        definesPresentationContext = true
    }


}


extension SearchFeedViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        
        let searchText = searchController.searchBar.text ?? ""

        
        print(searchText)
//        guard !searchText.isEmpty else {
//            resultsVC.items.removeAll()
//            resultsVC.getAllUsers()
//            return
//        }
        firestore.getUser(username: searchText.lowercased()) { (user) in
            self.resultsVC.items.removeAll()
            self.resultsVC.items = [user]
            self.resultsVC.adapter.performUpdates(animated: true, completion: nil)
        }
            
    }
}

extension SearchFeedViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 99
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "searchFeedCell", for: indexPath) as! ImageCell
        cell.numberLabel.text = String(indexPath.row)
        return cell
    }
    

}

extension SearchFeedViewController: ContentDynamicLayoutDelegate {
    func cellSize(indexPath: IndexPath) -> CGSize {
        return CGSize.init()
    }
}
