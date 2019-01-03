//
//  Counter.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import FirebaseFirestore

// counters/${ID}
struct Counter {
    let numShards: Int
    
    init(numShards: Int) {
        self.numShards = numShards
    }
}

// counters/${ID}/shards/${NUM}
struct Shard {
    let count: Int
    
    init(count: Int) {
        self.count = count
    }
}

