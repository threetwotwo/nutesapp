//
//  CommentActionCell.swift
//  nutesapp
//
//  Created by Gary Piong on 14/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

protocol CommentActionCellDelegate: class {
    func didTapHeart(cell: CommentActionCell)
    func didTapReply(cell: CommentActionCell)
}

class CommentActionCell: UICollectionViewCell, ListBindable {
    
//    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    
    weak var delegate: CommentActionCellDelegate? = nil
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? ActionViewModel else { return }
        likesLabel.text = "\(viewModel.likes)"
        let image = viewModel.didLike ? "heart_filled" : "heart_bordered"
        likeButton.setImage(UIImage(named: image), for: [])
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        likeButton.addTarget(self, action: #selector(onHeart), for: .touchUpInside)
        replyButton.addTarget(self, action: #selector(onReply), for: .touchUpInside)
    }
    
    @objc func onHeart() {
        delegate?.didTapHeart(cell: self)
    }
    
    @objc func onReply() {
        delegate?.didTapReply(cell: self)
    }
}
