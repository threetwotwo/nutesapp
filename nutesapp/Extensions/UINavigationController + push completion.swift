//
//  UINavigationController + push completion.swift
//  nutesapp
//
//  Created by Gary Piong on 19/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    public func pushViewController(viewController: UIViewController,
                                   animated: Bool,
                                   completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }
    
}
