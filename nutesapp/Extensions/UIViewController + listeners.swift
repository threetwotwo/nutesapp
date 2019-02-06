//
//  UIViewController + listeners.swift
//  nutesapp
//
//  Created by Gary Piong on 05/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit

extension UIViewController {
    
    func addObservers(observers: [Observer], selector: Selector) {
        
        for observer in observers {
            let name: Notification.Name
            switch observer.type {
            case .follow:
                name = .followedUser
            case .unfollow:
                name = .unfollowedUser
            }
            NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
        }
        
    }
}
