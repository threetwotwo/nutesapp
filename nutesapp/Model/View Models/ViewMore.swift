//
//  ViewMore.swift
//  nutesapp
//
//  Created by Gary Piong on 28/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class ViewMore: ListDiffable {
    let comment: Comment
    let type: ViewMoreType
    let count: Int
    
    init(comment: Comment, type: ViewMoreType, count:Int) {
        self.comment = comment
        self.type = type
        self.count = count
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return (comment.id) as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? ViewMore else { return false }
        return (self.comment.id) == (object.comment.id)
    }
}

enum ViewMoreType {
    case reply, root
}
