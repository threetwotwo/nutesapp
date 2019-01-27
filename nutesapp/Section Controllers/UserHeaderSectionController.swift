//
//  UserHeaderSectionController.swift
//  nutesapp
//
//  Created by Gary Piong on 06/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit
import YPImagePicker

class UserHeaderSectionController: ListBindingSectionController<User>, ListBindingSectionControllerDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UserHeaderDataCellDelegate {
    
    var user: User? = nil
    var firestore = FirestoreManager.shared
    var followerCount: Int? = nil
    weak var imageView: UIImageView!
    var isFollowing: Bool?
    
    override init() {
        super.init()
        dataSource = self
    }
    
    func presentPicker() {
        var config = YPImagePickerConfiguration()
        // [Edit configuration here ...]
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = true
        config.usesFrontCamera = true
        config.showsFilters = true
        config.shouldSaveNewPicturesToAlbum = true
        config.albumName = "DefaultYPImagePickerAlbumName"
        config.startOnScreen = YPPickerScreen.photo
        config.screens = [.photo, .library]
        config.showsCrop = .none
        config.targetImageSize = YPImageSize.cappedTo(size: 600)
        config.overlayView = UIView()
        config.hidesStatusBar = true
        config.hidesBottomBar = false
        config.preferredStatusBarStyle = UIStatusBarStyle.default
        
        // Build a picker with your configuration
        let picker = YPImagePicker(configuration: config)
        
        picker.didFinishPicking { [unowned picker] (items, _) in
            if let photo = items.singlePhoto {
                self.firestore.updateProfile(image: photo.image, completion: {
                    self.imageView.image = photo.image
                    UserDefaultsManager().updateUserPic(imageData: photo.image.pngData()!)
                })
            }
            picker.dismiss(animated: true, completion: nil)
        }
        viewController?.present(picker, animated: true, completion: nil)
    }
    
    func didTapFollowButton(cell: UserHeaderDataCell) {
        
        guard let user = object else {return}
        
        guard user.username != firestore.currentUser.username else {
            presentPicker()
            return
        }
        
        guard let isFollowing = isFollowing else { return }
        
        let buttonTitle = isFollowing ? "Follow" : "Unfollow"
        let loadingTitle = isFollowing ? "Unfollowing" : "Following"
        
        cell.followButton.setTitle(loadingTitle, for: [])

        if isFollowing {
            firestore.unfollowUser(withUsername: user.username) {
                cell.followButton.setTitle(buttonTitle, for: [])
                self.isFollowing = !self.isFollowing!
            }
        } else {
            firestore.followUser(withUsername: user.username) {
                cell.followButton.setTitle(buttonTitle, for: [])
                self.isFollowing = !self.isFollowing!
            }
        }
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
        guard let object = object as? User else { fatalError() }
        
        let results: [ListDiffable] = [
            UserImageViewModel(username: object.username, fullname: object.fullname, url: object.url),
            UserDataViewModel(username: object.username, postCount: "", followerCount: "\(object.followerCount)", followingCount: "", isFollowing: false),
            UserDetailViewModel(fullname: object.fullname, description: "ok boi")
        ]
        
        return results
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, cellForViewModel viewModel: Any, at index: Int) -> UICollectionViewCell & ListBindable {
        
        let identifier: String
        
        guard let context = collectionContext else { fatalError() }
        
        switch viewModel {
            
        case is UserImageViewModel:
            identifier = "userImage"
        case is UserDataViewModel:
            identifier = "userData"
        case is UserDetailViewModel:
            identifier = "userDetail"

        default:
            identifier = "userImage"
        }
        
        let cell = context.dequeueReusableCellFromStoryboard(withIdentifier: identifier, for: self, at: index)
        
        if let cell = cell as? UserHeaderImageCell {
            self.imageView = cell.imageView
        }
    
        if let cell = cell as? UserHeaderDataCell {
            
            cell.delegate = self
            
            DatabaseManager().getPostCount(username: (object?.username)!) { (count) in
                cell.postsLabel.text = "\(count)"
            }
            
            DatabaseManager().getFollowerCount(username: (object?.username)!) { (count) in
                cell.followersLabel.text = "\(count)"
            }
            
            DatabaseManager().getFollowingCount(username: (object?.username)!) { (count) in
                cell.followingLabel.text = "\(count)"
            }

            if firestore.currentUser.username != object?.username {
                firestore.isFollowing(follower: firestore.currentUser.username, followed: (object?.username)!) { (isFollowing) in
                    self.isFollowing = isFollowing
                    cell.followButton.setTitle(isFollowing ? "Unfollow" : "Follow", for: [])
                }
                
            }
        }
        
        return cell as! UICollectionViewCell & ListBindable
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, sizeForViewModel viewModel: Any, at index: Int) -> CGSize {
        
        guard let context = collectionContext else { fatalError() }
        
        let width = context.containerSize.width
        let height: CGFloat
        
        switch viewModel {
        case is UserImageViewModel:
            height = 128
            return CGSize(width: 144, height: height)
        case is UserDataViewModel:
            height = 128
            return CGSize(width: width - 144, height: height)
        case is UserDetailViewModel:
            height = 62

        default:
            height = 0
        }
        
        return CGSize(width: width, height: height)
    }
    
}
