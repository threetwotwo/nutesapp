//
//  IGViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 11/03/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class IGViewController: UIViewController {
    
    //MARK: - Variables
    
    var items: [ListDiffable] = []
    var firestore = FirestoreManager.shared
    let spinToken = "spinner"
    var isLoading = false
    
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
    
//    var lastSnapshot: DocumentSnapshot?
    
    //MARK: - Adapter
    
    lazy var adapter: ListAdapter = {
        let adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 1)
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
        return adapter
    }()
}

//MARK: - ListAdapterDataSource

extension IGViewController: ListAdapterDataSource {
    
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return items
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        if let obj = object as? String, obj == spinToken {
            return spinnerSectionController()
        }
        
        return ListSectionController()
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
}

//MARK: - UIScrollViewDelegate

extension IGViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !isLoading && distance < 200 {
            isLoading = true
            adapter.performUpdates(animated: true)
        }
    }
}
