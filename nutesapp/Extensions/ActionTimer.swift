//
//  ActionTimer.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation

final class ActionTimer {
    
    var resetSeconds: Int!
    
    var seconds: Int!
    
    var timer = Timer()
    
    init(seconds: Int) {
        self.seconds = seconds
        self.resetSeconds = seconds
    }
    
    func start(completion:@escaping ()->()) {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true
            , block: { (timer) in
                self.updateTimer {
                    completion()
                }
        })
    }
    
    @objc func updateTimer(completion:()->()) {
        print(self.seconds)
        self.seconds -= 1
        if self.seconds == 0 {
            print("time's up!")
            invalidate()
            reset()
            completion()
        }
    }
    
    func reset() {
        seconds = resetSeconds
    }
    
    func invalidate() {
        timer.invalidate()
    }
}
