//
//  ImageCell.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit
import SDWebImage

class ImageCell: UICollectionViewCell, ListBindable {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func bindViewModel(_ viewModel: Any) {
        
        guard let viewModel = viewModel as? ImageViewModel else { return }
        
        imageView.sd_setImage(with: URL(string: viewModel.url))
    }
    
}
