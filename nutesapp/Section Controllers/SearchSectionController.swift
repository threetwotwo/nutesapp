//
//  SearchSectionController.swift
//  nutesapp
//
//  Created by Gary Piong on 08/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class SearchSectionController: ListBindingSectionController<User>, ListBindingSectionControllerDataSource {
    
    var user: User?
    
    override init() {
        super.init()
        dataSource = self
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
        guard let object = object as? User else { fatalError() }
        
        self.user = object
        
        let results: [ListDiffable] = [
            UserHeaderViewModel(username: object.username, fullname: object.fullname, posts: object.postCount, followers: object.followerCount, following: object.followingCount, isFollowing: object.isFollowing, url: object.url)
        ]
        
        return results
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, cellForViewModel viewModel: Any, at index: Int) -> UICollectionViewCell & ListBindable {
        
        let identifier: String
        
        guard let context = collectionContext else { fatalError() }
        
        switch viewModel {
            
        case is UserHeaderViewModel:
            identifier = "searchCell"
        default:
            identifier = "searchCell"
        }
        
        let cell = context.dequeueReusableCellFromStoryboard(withIdentifier: identifier, for: self, at: index)
        
        return cell as! UICollectionViewCell & ListBindable
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, sizeForViewModel viewModel: Any, at index: Int) -> CGSize {
        
        guard let context = collectionContext else { fatalError() }
        
        let width = context.containerSize.width
        
        return CGSize(width: width, height: 50)
    }
    
    override func didSelectItem(at index: Int) {
        
        guard let user = user
        ,let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserVC") as? UserViewController else { return }
        
        vc.user = user
        viewController?.navigationController?.pushViewController(vc, animated: true)
        
    }
}
