//
//  UserDetailViewModel.swift
//  nutesapp
//
//  Created by Gary Piong on 07/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

final class UserDetailViewModel: ListDiffable {
    
    let fullname: String
    let description: String
    
    init(fullname: String, description: String) {
        self.fullname = fullname
        self.description = description
    }
    
    //Since there will only be one PostHeaderViewModel in one Post, we can hardcode an identifier
    //This will enforce only a single model and cell being used
    func diffIdentifier() -> NSObjectProtocol {
        return "userDetail" as NSObjectProtocol
    }
    
    //It is important to write a good equality method for the view model
    //Because anything something changes, forcing the models to not be equal, the cell will be refresed
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? UserDetailViewModel else {return false}
        return fullname == object.fullname
    }
}
