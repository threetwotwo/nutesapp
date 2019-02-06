//
//  ActionViewModel.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class ActionViewModel: ListDiffable {
    
    let likes: Int
    let followedUsernames: [String]
    let didLike: Bool
    let timestamp: Date
    
    init(likes: Int, followedUsernames: [String], didLike: Bool, timestamp: Date) {
        self.likes = likes
        self.followedUsernames = followedUsernames
        self.didLike = didLike
        self.timestamp = timestamp
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return "action" as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? ActionViewModel else {return false}
        return likes == object.likes
    }
}
