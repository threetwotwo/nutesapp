//
//  UserHeaderDataCell.swift
//  nutesapp
//
//  Created by Gary Piong on 24/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

protocol UserHeaderDataCellDelegate: class {
    func didTapFollowButton(cell: UserHeaderDataCell)
    func didTapUnfollowButton(cell: UserHeaderDataCell)
}

class UserHeaderDataCell: UICollectionViewCell, ListBindable {
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var unfollowButton: UIButton!
    
    weak var delegate: UserHeaderDataCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        unfollowButton.isHidden = true
        followButton.addTarget(self, action: #selector(onFollow), for: .touchUpInside)
        unfollowButton.addTarget(self, action: #selector(onUnfollow), for: .touchUpInside)
    }
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? UserDataViewModel else { return }

        postsLabel.text = "\(viewModel.postCount)"
        followersLabel.text = "\(viewModel.followerCount)"
        followingLabel.text = "\(viewModel.followingCount)"
        

    }
    
    
    @objc func onFollow() {
        delegate?.didTapFollowButton(cell: self)
    }
    
    @objc func onUnfollow() {
        delegate?.didTapUnfollowButton(cell: self)
    }
    
}
