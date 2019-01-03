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
        guard let viewModel = viewModel as? Comment else { return }
        textLabel.attributedText = AttributedText.constructComment(username: viewModel.username, text: viewModel.text)
    }
}
