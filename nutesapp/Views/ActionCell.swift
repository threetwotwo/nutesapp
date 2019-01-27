//
//  ActionCell.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

protocol ActionCellDelegate: class {
    func didTapHeart(cell: ActionCell)
    func didTapComment(cell: ActionCell)
}

class ActionCell: UICollectionViewCell, ListBindable {
    
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    
    weak var delegate: ActionCellDelegate? = nil
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? ActionViewModel else { return }
        //        likesLabel.text  = "\(viewModel.likes) likes"
        let attributedText = AttributedText.constructLikesLabel(totalLikes: viewModel.likes, followedLikes: viewModel.followedUsernames.count, followedUsernames: viewModel.followedUsernames)
        likesLabel.attributedText = attributedText
        let image = viewModel.didLike ? "heart_filled" : "heart_bordered"
        likeButton.setImage(UIImage(named: image), for: [])
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        likeButton.addTarget(self, action: #selector(onHeart), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(onComment), for: .touchUpInside)
    }
    
    
    @objc func onHeart() {
        delegate?.didTapHeart(cell: self)
    }
    
    @objc func onComment() {
        delegate?.didTapComment(cell: self)
    }
}
