//
//  ImageViewModel.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit
final class ImageViewModel: ListDiffable {
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return "image" as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? ImageViewModel else {
            return false
        }
        return self.url == object.url
    }
    
}
