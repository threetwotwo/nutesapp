//
//  SearchCell.swift
//  nutesapp
//
//  Created by Gary Piong on 07/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class SearchCell: UICollectionViewCell, ListBindable {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var fullnameLabel: UILabel!
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? UserImageViewModel else { return }
        
        if let url = URL(string: viewModel.url) {
            imageView.sd_setImage(with: url)
        }
        
        //round the corners
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        
        usernameLabel.text = viewModel.username
        fullnameLabel.text = viewModel.fullname
    }
    
}
