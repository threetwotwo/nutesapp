//
//  UIViewController + keyboardNotifs.swift
//  nutesapp
//
//  Created by Gary Piong on 04/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let barHeight = tabBarController?.tabBar.frame.height {
            if self.view.frame.origin.y == 0 {
            
                UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                    self.view.frame.origin.y -= (keyboardSize.height - barHeight)
                }, completion: nil)

            }
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if self.view.frame.origin.y != 0 {
            UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                self.view.frame.origin.y = 0
            }, completion: nil)
        }
    }
}
