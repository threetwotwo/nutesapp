//
//  UserHeaderSectionController.swift
//  nutesapp
//
//  Created by Gary Piong on 06/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class UserHeaderSectionController: ListBindingSectionController<User>, ListBindingSectionControllerDataSource {
    
    override init() {
        super.init()
        dataSource = self
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
        guard let object = object as? User else { fatalError() }
        
        let results: [ListDiffable] = [
            UserHeaderViewModel(username: object.username, fullname: object.fullname, posts: object.postCount, followers: object.followerCount, following: object.followingCount, isFollowing: object.isFollowing, url: object.url),
            UserDetailViewModel(fullname: object.fullname, description: "")
        ]
        
        return results
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, cellForViewModel viewModel: Any, at index: Int) -> UICollectionViewCell & ListBindable {
        
        let identifier: String
        
        guard let context = collectionContext else { fatalError() }
        
        switch viewModel {
            
        case is UserHeaderViewModel:
            identifier = "userHeaderCell"
        case is UserDetailViewModel:
            identifier = "userDetailCell"
        default:
            identifier = "userHeaderCell"
        }
        
        let cell = context.dequeueReusableCellFromStoryboard(withIdentifier: identifier, for: self, at: index)
        
        return cell as! UICollectionViewCell & ListBindable
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, sizeForViewModel viewModel: Any, at index: Int) -> CGSize {
        
        guard let context = collectionContext else { fatalError() }
        
        let width = context.containerSize.width
        let height: CGFloat
        
        switch viewModel {
        case is UserHeaderViewModel:
            height = 128
        case is UserDetailViewModel:
            height = 62
        default:
            height = 0
        }
        
        return CGSize(width: width, height: height)
    }
    
}
