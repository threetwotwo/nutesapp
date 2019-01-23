//
//  CommentCell.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class CommentCell: UICollectionViewCell, ListBindable {
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView?
    
    
    func bindViewModel(_ viewModel: Any) {
        
        var username: String = ""
        
        if let viewModel = viewModel as? Comment  {
            textLabel.attributedText = AttributedText.constructComment(username: viewModel.username, text: viewModel.text)
            username = viewModel.username
        }
        
        else if let viewModel = viewModel as? CommentViewModel  {
        textLabel.attributedText = AttributedText.constructComment(username: viewModel.username, text: viewModel.text)
        username = viewModel.username
        }
        
        if let imageView = imageView {
            imageView.layer.cornerRadius = imageView.frame.size.width/2
            DatabaseManager().getUserURL(username: username) { (url) in
                if let url = URL(string: url) {
                    imageView.sd_setImage(with: url)
                }
            }
        }

    }
}
