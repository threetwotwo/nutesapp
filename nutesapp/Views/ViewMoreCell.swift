//
//  ViewMoreCell.swift
//  nutesapp
//
//  Created by Gary Piong on 28/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit

protocol ViewMoreCellDelegate: class {
    func viewMoreTapped(cell: ViewMoreCell)
}

class ViewMoreCell: UICollectionViewCell {
    @IBOutlet weak var viewMoreButton: UIButton!
    @IBOutlet weak var loadingindicator: UIActivityIndicatorView!
    
    @IBAction func viewMoreButtonTapped(_ sender: UIButton) {
        delegate?.viewMoreTapped(cell: self)
    }
    
    weak var delegate: ViewMoreCellDelegate? = nil
}
