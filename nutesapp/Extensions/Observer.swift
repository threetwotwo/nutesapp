//
//  Observer.swift
//  nutesapp
//
//  Created by Gary Piong on 06/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation

class Observer {
    let center: NotificationCenter
    let type: ObserverType
    
    init(center: NotificationCenter = .default, type: ObserverType) {
        self.center = center
        self.type = type
    }
    
    static func types(_ types: [ObserverType]) -> [Observer] {
        var results =  [Observer]()
        for type in types {
            results.append(Observer(type: type))
        }
        return results
    }
    
}

extension Observer {
    enum ObserverType {
        case unfollow
        case follow
    }
}

extension Notification.Name {
    static var followedUser: Notification.Name {
        return .init(rawValue: "Notifications.followedUser")
    }
    static var unfollowedUser: Notification.Name {
        return .init(rawValue: "Notifications.unfollowedUser")
    }
}

protocol Observable: class {
    func didChange(type: Observer.ObserverType, object: Any?)
}

extension Observable {
    func didChange(type: Observer.ObserverType, object: Any?) {
        switch type {
        case .follow:
            NotificationCenter.default.post(name: .followedUser, object: (type,object))
        case .unfollow:
            NotificationCenter.default.post(name: .unfollowedUser, object: (type,object))
        }
    }
}
