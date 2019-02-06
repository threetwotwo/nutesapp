//
//  TimestampViewModel.swift
//  nutesapp
//
//  Created by Gary Piong on 04/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

final class TimestampViewModel: ListDiffable {
    let date: Date
    
    init(date: Date) {
        self.date = date
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return "postTimestamp" as NSObjectProtocol
    }
    
    //It is important to write a good equality method for the view model
    //Because anything something changes, forcing the models to not be equal, the cell will be refresed
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return true
    }
}
