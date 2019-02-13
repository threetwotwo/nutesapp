//
//  UITextView + hashtags.swift
//  nutesapp
//
//  Created by Gary Piong on 11/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit

extension UITextView {
    
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // location of the tap
        var location = point
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top
        
        // find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < self.textStorage.length {
            // if the character is a link, handle the tap as UITextView normally would
            if (self.textStorage.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) != nil) {
                return self
            }
        }
        
        // otherwise return nil so the tap goes on to the next receiver
        return nil
    }
    
    func resolveHashTags() {
        
        // turn string in to NSString
        let nsText = NSString(string: self.text)
        
        // this needs to be an array of NSString.  String does not work.
        let words = nsText.components(separatedBy: CharacterSet(charactersIn: "@#ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_").inverted)
        
        // you can staple URLs onto attributed strings
        let attrString = NSMutableAttributedString()
        attrString.setAttributedString(self.attributedText)
        // tag each word if it has a hashtag
        for word in words {
            if word.count < 3 {
                continue
            }
            
            // a range is the character position, followed by how many characters are in the word.
            // we need this because we staple the "href" to this range.
            let matchRange:NSRange = nsText.range(of: word as String)
            
            // found a word that is prepended by a hashtag!
            // homework for you: implement @mentions here too.
            if word.hasPrefix("#") || word.hasPrefix("@") {
                
                // drop the hashtag
                let stringifiedWord = word.dropFirst()
                if let firstChar = stringifiedWord.unicodeScalars.first, NSCharacterSet.decimalDigits.contains(firstChar) {
                    // hashtag contains a number, like "#1"
                    // so don't make it clickable
                } else {
                    // set a link for when the user clicks on this word.
                    // it's not enough to use the word "hash", but you need the url scheme syntax "hash://"
                    // note:  since it's a URL now, the color is set to the project's tint color
                    attrString.addAttribute(NSAttributedString.Key.link, value: word, range: matchRange)

                }
                
            }
        }
        
        // we're used to textView.text
        // but here we use textView.attributedText
        // again, this will also wipe out any fonts and colors from the storyboard,
        // so remember to re-add them in the attrs dictionary above
        self.attributedText = attrString
    }
}
