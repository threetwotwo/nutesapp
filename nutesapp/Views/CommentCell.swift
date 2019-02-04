//
//  CommentCell.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

protocol CommentCellDelegate: class {
    func didTapHeart(cell: CommentCell)
}

class CommentCell: UICollectionViewCell, ListBindable {
    
    weak var delegate: CommentCellDelegate? = nil
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var likeButton: UIButton!
    
    func bindViewModel(_ viewModel: Any) {
        
        var username: String = ""
        
        guard let viewModel = viewModel as? CommentViewModel else { return }
        
        //configure button
        likeButton.addTarget(self, action: #selector(onHeart), for: .touchUpInside)
        let imageTitle = viewModel.didLike ? "heart_filled" : "heart_bordered"
        likeButton.setImage(UIImage(named: imageTitle), for: [])
        
        textLabel.attributedText = AttributedText.constructComment(username: viewModel.username, text: viewModel.text)
        username = viewModel.username
        
        
        if let imageView = imageView {
            imageView.layer.cornerRadius = imageView.frame.size.width/2
            DatabaseManager().getUserURL(username: username) { (url) in
                if let url = URL(string: url) {
                    imageView.sd_setImage(with: url)
                }
            }
        }

    }
    
    @objc func onHeart() {
        delegate?.didTapHeart(cell: self)
    }
}
