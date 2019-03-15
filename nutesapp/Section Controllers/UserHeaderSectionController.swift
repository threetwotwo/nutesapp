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

class UserHeaderSectionController: ListBindingSectionController<User>, ListBindingSectionControllerDataSource, UINavigationControllerDelegate, UserHeaderDataCellDelegate, Observable {
    
    var user: User? = nil
    var firestore = FirestoreManager.shared

    weak var imageView: UIImageView!
    weak var fullnameLabel: UILabel!
    
    var isFollowing: Bool?
    var userData: UserDataViewModel?
    
    override init() {
        super.init()
        dataSource = self
    }
    
    func didTapUnfollowButton(cell: UserHeaderDataCell) {
        guard let user = object else {return}

        cell.unfollowButton.isHidden = true
        firestore.unfollow(uid: user.uid) {
            cell.followButton.setTitle("Follow", for: [])
            self.isFollowing = false
            //notify feedvc
            self.didChange(type: .unfollow, object: user.username)
        }
    }
    
    func didTapFollowButton(cell: UserHeaderDataCell) {
        guard let user = object else {return}
        
        guard user.username != firestore.currentUser.username else {
            presentPicker()
            return
        }
        
        if self.isFollowing ?? false {
            
            //Message
            
            let vc = DirectMessageViewController()
            vc.user = object
            viewController?.navigationController?.pushViewController(vc, animated: true)
        } else {
            
            //Follow
            
            firestore.follow(uid: user.uid) {
                cell.unfollowButton.isHidden = false
                cell.followButton.setTitle("Message", for: [])
                self.isFollowing = true
                //Observable - notify feedvc
                self.didChange(type: .follow, object: user.username)
            }
        }
    
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
        guard let object = object as? User else { fatalError() }
        
        let results: [ListDiffable] = [
            UserImageViewModel(username: object.username, fullname: object.fullname, url: object.url),
            UserDataViewModel(username: object.username, postCount: userData?.postCount ?? "0", followerCount: userData?.followerCount ?? "0", followingCount: userData?.followingCount ?? "0", isFollowing: false),
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
        
        if let cell = cell as? UserHeaderDetailCell {
            fullnameLabel = cell.fullnameLabel
        }
        
        if let cell = cell as? UserHeaderImageCell {
            self.imageView = cell.imageView
        }
    
        if let cell = cell as? UserHeaderDataCell,
            let uid = object?.uid {
            
            cell.delegate = self
            
            if self.isFollowing == nil {
                let buttonTitle = uid == firestore.currentUser.uid ? "Edit Profile" : "Loading"
                cell.followButton.setTitle(buttonTitle, for: [])
            }

            
            if userData == nil {
                
                if user?.url == "" || user?.url == nil {
                    firestore.getUser(username: user?.username ?? "") { (user) in
                        self.imageView.sd_setImage(with: URL(string: user.url))
                        self.fullnameLabel.text = user.fullname
                    }
                }
                
                let dsg = DispatchGroup()
                
                var posts = 0
                var followers = 0
                var following = 0

                dsg.enter()
                DatabaseManager().getPostCount(uid: uid) { (count) in
                    print("getPostCount")
                    posts = count
                    dsg.leave()
                }
                
                dsg.enter()
                DatabaseManager().getFollowerCount(uid: uid) { (count) in
                    followers = count
                    dsg.leave()
                }
                
                dsg.enter()
                DatabaseManager().getFollowingCount(uid: uid) { (count) in
                    following = count
                    dsg.leave()
                }
                
                dsg.notify(queue: .main) {
                    self.userData = UserDataViewModel(username: uid, postCount: "\(posts)", followerCount: "\(followers)", followingCount: "\(following)", isFollowing: false)
                    cell.postsLabel.text = "\(posts)"
                    cell.followersLabel.text = "\(followers)"
                    cell.followingLabel.text = "\(following)"
                    //Tells the section controller to query for new view models, diff the changes, and update its cells.
                    self.update(animated: true, completion: nil)
                }
            }
    
            
            if firestore.currentUser.username != object?.username && self.isFollowing == nil {
                print("getting isfollowing data from firestore")
                firestore.isFollowing(follower: firestore.currentUser.uid, followed: uid) { (isFollowing) in
                    self.isFollowing = isFollowing
                    cell.followButton.setTitle(isFollowing ? "Message" : "Follow", for: [])
                    cell.unfollowButton.isHidden = !isFollowing
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

extension UserHeaderSectionController {
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
                self.firestore.updateProfile(image: photo.image, completion: { url in
                    if let url = url {
                        self.imageView.sd_setImage(with: url)
                    }
                    UserDefaultsManager().updateUserPic(imageData: photo.image.pngData()!)
                })
            }
            picker.dismiss(animated: true, completion: nil)
        }
        viewController?.present(picker, animated: true, completion: nil)
    }
}
