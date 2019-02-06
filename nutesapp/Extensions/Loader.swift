//
//  Loader.swift
//  nutesapp
//
//  Created by Gary Piong on 06/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

final class Loader {
    static let spintoken = "spinner" as ListDiffable
    
    var isLoading: Bool
    var at: LoaderLocation = .bottom
    
    init(isLoading: Bool) {
        self.isLoading = isLoading
    }
}

enum LoaderLocation {
    case top, bottom
}
