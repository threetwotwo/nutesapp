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
import Hue

class SearchFeedViewController: UIViewController {
    
    //MARK: - IBOutlets

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var gradientView: UIView!
    
    //MARK: - Variables

    var searchController: UISearchController!
    let resultsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Identifier.storyboard.searchresultsVC) as! SearchResultsViewController

    let firestore = FirestoreManager.shared
    let spinToken = "spinner"
    var lastSnapshots = [String:DocumentSnapshot]()
    var loading = false
    
    lazy var gradient: CAGradientLayer = [
        UIColor(hex: "#FD4340"),
        UIColor(hex: "#CE2BAE")
        ].gradient { gradient in
            gradient.speed = 0
            gradient.timeOffset = 0
            
            return gradient
    }
    
    lazy var animation: CABasicAnimation = { [unowned self] in
        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = 1.0
        animation.isRemovedOnCompletion = false
        
        return animation
        }()
    
    var cachedIDs = [String]()
    //false if only need to load one post
    var shouldLoadMore = true
    
    var items = [ListDiffable]()
    var posts = [Post]()
    
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

        firestore.getTopPosts(limit: 99) { (posts, lastSnap) in
            
            print("got top posts")
            
            self.posts.append(contentsOf: posts)
            self.collectionView.reloadData()
        }
        
        setUpSearchController()
        
        let layout = InstagramStyleFlowLayout()
        layout.delegate = self
        layout.cellsPadding = ItemsPadding(horizontal: 10, vertical: 10)
        collectionView.setCollectionViewLayout(layout, animated: true)
        
        collectionView.dataSource = self

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        guard let navigationController = navigationController else { return }

        gradientView.layer.addSublayer(gradient)
        collectionView.backgroundView = gradientView
        gradient.timeOffset = 0
        gradient.bounds = navigationController.view.bounds
        gradient.frame = navigationController.view.bounds
        gradient.add(animation, forKey: "Change Colors")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let someView: UIView = object as! UIView? {
            
            if (someView == self.searchController.searchResultsController?.view &&
                (keyPath == "hidden") &&
                (searchController.searchResultsController?.view.isHidden)! &&
                searchController.searchBar.isFirstResponder) {
                
                searchController.searchResultsController?.view.isHidden = false
            }
            
        }
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
        
        searchController.searchResultsController?.view.addObserver(self, forKeyPath: "hidden", options: [], context: nil)
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
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "searchFeedCell", for: indexPath) as! ImageCell
        
        let post = posts[indexPath.row]
        
        cell.imageView.sd_setImage(with: URL(string: post.postURL))
    
        return cell
    }
    

}

extension SearchFeedViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        searchController.searchResultsController?.view.isHidden = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if (searchText.count == 0) {
            searchController.searchResultsController?.view.isHidden = false
        }
    }
    
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchController.searchResultsController?.view.isHidden = true
    }
}

extension SearchFeedViewController: ContentDynamicLayoutDelegate {

    func cellSize(indexPath: IndexPath) -> CGSize {
        return CGSize.init()
    }
}
