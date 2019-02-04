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
}

class UserHeaderDataCell: UICollectionViewCell, ListBindable {
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    weak var delegate: UserHeaderDataCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        followButton.addTarget(self, action: #selector(onFollow), for: .touchUpInside)
    }
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? UserDataViewModel else { return }

        postsLabel.text = "\(viewModel.postCount)"
        followersLabel.text = "\(viewModel.followerCount)"
        followingLabel.text = "\(viewModel.followingCount)"
        
        let buttonTitle = viewModel.username == FirestoreManager.shared.currentUser.username ? "Edit Profile" : "Loading"
        
        followButton.setTitle(buttonTitle, for: [])
    }
    
    
    @objc func onFollow() {
        delegate?.didTapFollowButton(cell: self)
    }
    
}
