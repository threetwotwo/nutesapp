//
//  Avatar.swift
//  nutesapp
//
//  Created by Gary Piong on 14/03/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

//An object to represent user that contains the bare minimum:
//the user's username & profile picture

final class Avatar: ListDiffable {
    
    let uid: String
    let username: String
    let photoURL: String
    
    
    init(uid: String, username: String, photoURL: String) {
        self.uid = uid
        self.username = username
        self.photoURL = photoURL
    }

    func diffIdentifier() -> NSObjectProtocol {
        return uid as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? Avatar else { return false }
        return self.uid == object.uid
    }
}


