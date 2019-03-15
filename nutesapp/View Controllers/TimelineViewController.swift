//
//  TimelineViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 11/03/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class TimelineViewController: IGViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        adapter.collectionView = self.collectionView
    }

}


//MARK: - ListDataSource

extension TimelineViewController {
    override func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return ListSectionController()
    }
}
