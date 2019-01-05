//
//  UITextView + centerVertically.swift
//  nutesapp
//
//  Created by Gary Piong on 04/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit

extension UITextView {
    func alignTextVerticallyInContainer() {
//        
//        let contentHeight = self.contentSize.height
//        let containerHeight = self.bounds.size.height
//        
//        guard contentHeight < containerHeight && !self.text.isEmpty else {return}
        
        var topCorrect: CGFloat
        
        if self.text.isEmpty {
            topCorrect = (self.bounds.size.height - 0 * self.zoomScale) / 2
        } else {
            topCorrect = (self.bounds.size.height - self.contentSize.height * self.zoomScale) / 2
        }
        print("height: \(bounds.size.height), contentSize: \(contentSize.height), topCorrect: \(topCorrect)")
        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect
        self.contentInset.top = topCorrect
    }
    
}
