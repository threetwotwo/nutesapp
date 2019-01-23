//
//  UserHeaderCell.swift
//  nutesapp
//
//  Created by Gary Piong on 07/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

protocol UserHeaderCellDelegate: class {
    func didTapFollowButton(cell: UserHeaderCell)
}

class UserHeaderCell: UICollectionViewCell, ListBindable {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    weak var delegate: UserHeaderCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        followButton.addTarget(self, action: #selector(onFollow), for: .touchUpInside)
    }
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? UserHeaderViewModel else { return }
        
        if let url = URL(string: viewModel.url) {
            imageView.sd_setImage(with: url)
        }
        
        //round the corners
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        
        postsLabel.text = "\(viewModel.postCount)"
        followersLabel.text = "\(viewModel.followerCount)"
        followingLabel.text = "\(viewModel.followingCount)"
        
        let buttonTitle = viewModel.username == FirestoreManager.shared.currentUser.username ? "Edit Profile" : (viewModel.isFollowing ? "Unfollow" : "Follow")
        
        followButton.setTitle(buttonTitle, for: [])
    }
    
    @objc func onFollow() {
        delegate?.didTapFollowButton(cell: self)
    }
    
}
