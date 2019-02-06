//
//  Date + timeAgo.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation

extension Date {
    func timeAgoDisplay(comment: Bool = false) -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        
        
        if secondsAgo < minute {
            return "\(secondsAgo)" + (comment ? "s" : " seconds ago")
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute)" + (comment ? "m" : " minutes ago")
        } else if secondsAgo < day {
            return "\(secondsAgo / hour)" + (comment ? "h" : " hours ago")
        } else if secondsAgo < week {
            return "\(secondsAgo / day)" + (comment ? "d" : " days ago")
        }
        
        return "\(secondsAgo / week)" + (comment ? "w" : " weeks ago")
    }
}
