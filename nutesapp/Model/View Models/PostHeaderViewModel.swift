//
//  PostHeaderViewModel.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

final class PostHeaderViewModel: ListDiffable {
    let postId: String
    let username: String
    let timestamp: Date
    let url: String

    init(postId: String, username: String, timestamp: Date, url: String) {
        self.postId = postId
        self.username = username
        self.timestamp = timestamp
        self.url = url
    }
    
    //Since there will only be one PostHeaderViewModel in one Post, we can hardcode an identifier
    //This will enforce only a single model and cell being used
    func diffIdentifier() -> NSObjectProtocol {
        return "postHeader" as NSObjectProtocol
    }
    
    //It is important to write a good equality method for the view model
    //Because anything something changes, forcing the models to not be equal, the cell will be refresed
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? PostHeaderViewModel else {return false}
        return username == object.username
            && timestamp == object.timestamp
    }
}
