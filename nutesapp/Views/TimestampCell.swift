//
//  TimestampCell.swift
//  nutesapp
//
//  Created by Gary Piong on 04/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

class TimestampCell: UICollectionViewCell, ListBindable {
    
    @IBOutlet weak var timestampLabel: UILabel!
    
    func bindViewModel(_ viewModel: Any) {
        if let timestamp = viewModel as? TimestampViewModel {
            timestampLabel.text = timestamp.date.timeAgoDisplay().uppercased()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        isUserInteractionEnabled = false
    }

}
