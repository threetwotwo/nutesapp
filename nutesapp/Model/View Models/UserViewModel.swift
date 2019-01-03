//
//  UserViewModel.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

final class UserViewModel: ListDiffable {
    let postID: String
    let username: String
    let timestamp: Date
    
    init(postID: String, username: String, timestamp: Date) {
        self.postID = postID
        self.username = username
        self.timestamp = timestamp
    }
    
    //Since there will only be one UserViewModel in one Post, we can hardcode an identifier
    //This will enforce only a single model and cell being used
    func diffIdentifier() -> NSObjectProtocol {
        return "user" as NSObjectProtocol
    }
    
    //It is important to write a good equality method for the view model
    //Because anything something changes, forcing the models to not be equal, the cell will be refresed
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? UserViewModel else {return false}
        return username == object.username
            && timestamp == object.timestamp
    }
}
