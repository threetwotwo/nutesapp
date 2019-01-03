//
//  CommentViewModel.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class CommentViewModel: ListDiffable {
    
    let username: String
    let text: String
    let timestamp: Date
    
    init(username: String, text: String, timestamp: Date) {
        self.username = username
        self.text = text
        self.timestamp = timestamp
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return (UUID().uuidString) as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return true
    }
}
