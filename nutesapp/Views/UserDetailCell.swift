//
//  UserDetailCell.swift
//  nutesapp
//
//  Created by Gary Piong on 07/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class UserDetailCell: UICollectionViewCell, ListBindable {
    
    @IBOutlet weak var fullnameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    func bindViewModel(_ viewModel: Any) {
    
        guard let viewModel = viewModel as? UserDetailViewModel else { fatalError() }
        fullnameLabel.text = viewModel.fullname
        descriptionLabel.text = "I am a weirdo (smileyface)"
    }

}
