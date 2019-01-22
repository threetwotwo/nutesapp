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
    
    func bindViewModel(_ viewModel: Any) {
        if let viewModel = viewModel as? Comment  {
            textLabel.attributedText = AttributedText.constructComment(username: viewModel.username, text: viewModel.text)
        }
        if let viewModel = viewModel as? CommentViewModel  {
        textLabel.attributedText = AttributedText.constructComment(username: viewModel.username, text: viewModel.text)
        }
    }
}
