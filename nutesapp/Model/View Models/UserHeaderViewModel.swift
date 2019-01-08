//
//  UserHeaderViewModel.swift
//  nutesapp
//
//  Created by Gary Piong on 06/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

final class UserHeaderViewModel: ListDiffable {
    let username: String
    let fullname: String
    let url: String
    let posts: Int
    let followers: Int
    let following: Int
    let isFollowing: Bool
    
    init(username: String, fullname: String, posts: Int, followers: Int, following: Int, isFollowing: Bool, url: String) {
        self.username = username
        self.fullname = fullname
        self.posts = posts
        self.followers = followers
        self.following = following
        self.isFollowing = isFollowing
        self.url = url
    }
    
    //Since there will only be one PostHeaderViewModel in one Post, we can hardcode an identifier
    //This will enforce only a single model and cell being used
    func diffIdentifier() -> NSObjectProtocol {
        return "userHeader" as NSObjectProtocol
    }
    
    //It is important to write a good equality method for the view model
    //Because anything something changes, forcing the models to not be equal, the cell will be refresed
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? UserHeaderViewModel else {return false}
        return username == object.username
    }
}
