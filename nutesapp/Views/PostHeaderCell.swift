//
//  PostHeaderCell.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class PostHeaderCell: UICollectionViewCell, ListBindable {
    
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? PostHeaderViewModel else { return }
        usernameLabel.text = viewModel.username
    }
    
}
