//
//  UserBodySectionController.swift
//  nutesapp
//
//  Created by Gary Piong on 07/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class UserBodySectionController: ListBindingSectionController<User>, ListBindingSectionControllerDataSource {
    
    override init() {
        super.init()
        dataSource = self
        self.minimumInteritemSpacing = 2
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 2, right: 0)
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
        
        guard let object = object as? Post else { fatalError() }
        
        let results: [ListDiffable] = [
            ImageViewModel(url: object.postURL)
        ]
        
        return results
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, cellForViewModel viewModel: Any, at index: Int) -> UICollectionViewCell & ListBindable {
        
        let identifier: String
        
        guard let context = collectionContext else { fatalError() }
        
        switch viewModel {
            
        case is ImageViewModel:
            identifier = "userBody"
        default:
            identifier = "userBody"
        }
        
        return context.dequeueReusableCellFromStoryboard(withIdentifier: identifier, for: self, at: index) as! UICollectionViewCell & ListBindable
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, sizeForViewModel viewModel: Any, at index: Int) -> CGSize {
        
        return self.itemSize
    }
    
    
    fileprivate var itemSize: CGSize {
        let collectionViewWidth = collectionContext?.containerSize.width ?? 0
        let itemWidth = ((collectionViewWidth - 4) / 3)
        let heightRatio: CGFloat = 1
        return CGSize(width: itemWidth, height: itemWidth * heightRatio)
    }
}

