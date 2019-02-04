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
    func didTapReply(cell: CommentActionCell)
}

class CommentActionCell: UICollectionViewCell, ListBindable {
    
//    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var timeststampLabel: UILabel!
    @IBOutlet weak var likesView: UIView!
    
    weak var delegate: CommentActionCellDelegate? = nil
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? ActionViewModel else { return }
        likesLabel.text = "\(viewModel.likes)"
        if viewModel.likes < 1 {
            likesView.isHidden = true
        } else {
            likesView.isHidden = false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        replyButton.addTarget(self, action: #selector(onReply), for: .touchUpInside)
    }
    
    @objc func onReply() {
        delegate?.didTapReply(cell: self)
    }
}
