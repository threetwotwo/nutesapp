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

protocol ImageCellDelegate: class {
    func doubleTapped(cell: ImageCell)
}

class ImageCell: UICollectionViewCell, ListBindable {
    
    @IBOutlet weak var imageView: UIImageView!
    
    weak var delegate: ImageCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        tap.numberOfTapsRequired = 2
        addGestureRecognizer(tap)
    }
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? ImageViewModel else { return }
        imageView.sd_setImage(with: URL(string: viewModel.url))
    }
    
    @objc func onDoubleTap() {
        delegate?.doubleTapped(cell: self)
    }
    
}
