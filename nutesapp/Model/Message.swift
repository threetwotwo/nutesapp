//
//  Message.swift
//  nutesapp
//
//  Created by Gary Piong on 15/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import MessageKit

final class Message: MessageType {
    
    var sender: Sender
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
    
    init(sender: Sender, messageID: String, timestamp: Date, kind: MessageKind) {
        self.sender = sender
        self.messageId = messageID
        self.sentDate = timestamp
        self.kind = kind
    }
}
