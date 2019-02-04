//
//  Router.swift
//  nutesapp
//
//  Created by Gary Piong on 24/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit

protocol RouterInput {
    func navigateToPushedViewController(value: Int)
}

final class Router: RouterInput {
    func navigateToPushedViewController(value: Int) {
        
    }
    
    
    weak var vc: UIViewController?
    
    init(vc: UIViewController) {
        self.vc = vc
    }
}


