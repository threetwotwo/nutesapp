//
//  UserHeaderSectionController.swift
//  nutesapp
//
//  Created by Gary Piong on 06/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

protocol UserHeaderSectionControllerDelegate: class {
    func followButtonPressed(user: User)
}

class UserHeaderSectionController: ListBindingSectionController<User>, ListBindingSectionControllerDataSource, UserHeaderCellDelegate {
    
    var user: User? = nil
    var firestore = FirestoreManager.shared
    var followerCount: Int? = nil
     var delegate: UserHeaderSectionControllerDelegate? = nil

    override init() {
        super.init()
        dataSource = self
    }
    
    func didTapFollowButton(cell: UserHeaderCell) {
        
        guard let user = object else {return}
        
        self.user?.isFollowing = !(self.user?.isFollowing)!

        let buttonTitle = user.isFollowing ? "Unfollow" : "Follow"
        self.followerCount = user.isFollowing ? self.followerCount ?? 0 + 1 : self.followerCount ?? 0 - 1
        
        if (self.user?.isFollowing)! {
            followerCount = followerCount! + 1
            firestore.followUser(withUsername: user.username) {
                print("followed \(user.username)")
            }
        } else {
            followerCount = followerCount! - 1
            firestore.unfollowUser(withUsername: user.username) {
                print("unfollowed \(user.username)")
            }
        }

        cell.followButton.setTitle(buttonTitle, for: [])
        cell.followersLabel.text = "\(followerCount!)"
        
        self.user = User(user: self.user!, followerCount: followerCount!, isFollowing: (self.user?.isFollowing)!)

        delegate?.followButtonPressed(user: self.user!)
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
        
        if let cell = cell as? UserHeaderCell,
            let model = viewModel as? UserHeaderViewModel {
            cell.delegate = self
            self.user = User(uid: "", fullname: model.fullname, email: "", username: model.username, postCount: model.postCount, followerCount: model.followerCount, followingCount: model.followingCount, isFollowing: model.isFollowing, url: "")
            self.followerCount = self.user?.followerCount
        }
        
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
