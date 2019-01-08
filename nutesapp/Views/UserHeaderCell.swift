//
//  UserHeaderCell.swift
//  nutesapp
//
//  Created by Gary Piong on 07/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class UserHeaderCell: UICollectionViewCell, ListBindable {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? UserHeaderViewModel else { return }
        
        postsLabel.text = "\(viewModel.posts)"
        followersLabel.text = "\(viewModel.followers)"
        followingLabel.text = "\(viewModel.following)"
        
        let buttonTitle = viewModel.username == FirestoreManager.shared.currentUser.username ? "Edit Profile" : (viewModel.isFollowing ? "Unfollow" : "Follow")
        
        followButton.setTitle(buttonTitle, for: [])
    }
    
    
}
