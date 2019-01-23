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

class UserHeaderSectionController: ListBindingSectionController<User>, ListBindingSectionControllerDataSource, UserHeaderCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User? = nil
    var firestore = FirestoreManager.shared
    var followerCount: Int? = nil
    var delegate: UserHeaderSectionControllerDelegate? = nil
    weak var imageView: UIImageView!
    
    override init() {
        super.init()
        dataSource = self
    }
    
    func openGallery()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            viewController?.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have perission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            viewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func openCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            viewController?.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            viewController?.present(alert, animated: true, completion: nil)
        }
    }
    //MARK:-- ImagePicker delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        picker.dismiss(animated: true) {
            self.firestore.updateProfile(image: selectedImage, completion: {
                self.imageView.image = selectedImage
            })
        }
        
    }
    
    func didTapFollowButton(cell: UserHeaderCell) {
        
        guard let user = object else {return}
        
        self.user = User(user: self.user!, followerCount: followerCount!, isFollowing: (self.user?.isFollowing)!)
        
        delegate?.followButtonPressed(user: self.user!)
        
        guard user.username != firestore.currentUser.username else {
            print("current user")
            let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.openCamera()
            }))
            
            alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
                self.openGallery()
            }))
            
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            
            viewController?.present(alert, animated: true, completion: nil)
            return
        }
        
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
            self.imageView = cell.imageView
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
