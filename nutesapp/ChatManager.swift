//
//  ChatManager.swift
//  nutesapp
//
//  Created by Gary Piong on 16/02/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import MessageKit
import FirebaseDatabase

final class ChatManager {
    
    let db = FirestoreManager.shared.db!
    let currentUser = FirestoreManager.shared.currentUser
    let rtdb = DatabaseManager().db
    
    func getChatID(with username: String, completion: @escaping (String)->()) {
        let current = currentUser?.username ?? ""
        let id = current < username ? "\(current)_\(username)" : "\(username)_\(current)"
        let query = db.collection("chats").document(id)
        query.getDocument(completion: { (snap, error) in
            
            guard error == nil else {
                print("error: chat not found")
                completion(id)
                return
            }
            
            if let chatID = snap?.documentID {
                completion(chatID)
            }
        })
    }
    
    func createChat(with username: String, completion: @escaping (String)->()) {
        let current = currentUser?.username ?? ""
        let id = current < username ? "\(current)_\(username)" : "\(username)_\(current)"
        let messageRef = db.collection("chats").document(id)
        let payload: [String:Any] = [
            "timestamp" : Timestamp(),
            "users" : [currentUser?.username ?? "", username]
        ]
        messageRef.setData(payload, completion: { (error) in
            if error == nil {
                completion(id)
            }
        })
    }
    
    func getMessage(documentSnapshot: QueryDocumentSnapshot) -> Message {
        let data = documentSnapshot.data()
        let username = data["username"] as? String ?? ""
        let text = data["text"] as? String ?? ""
        let timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
        
        let message: Message
        
        if text.isSingleEmoji {
            message = Message(sender: Sender(id: username, displayName: username), messageID: documentSnapshot.documentID, timestamp: timestamp.dateValue(), kind: .emoji(text))
        } else {
            message = Message(sender: Sender(id: username, displayName: username), messageID: documentSnapshot.documentID, timestamp: timestamp.dateValue(), kind: .text(text))
        }
        
        return message
    }
    
    func getMessages(documentSnapshots docs: [QueryDocumentSnapshot]) -> [Message] {
        var messages = [Message]()
        
        for doc in docs {
            messages.append(getMessage(documentSnapshot: doc))
        }
        return messages
    }
    
    func getMessages(chatID: String, completion: @escaping ([Message])->()) {
        let messagesRef = db.collection("chats").document(chatID).collection("messages").order(by: "timestamp", descending: false)
        
        messagesRef.getDocuments(completion: { (snap, error) in
            guard let docs = snap?.documents else { return }
            var messages = [Message]()

            for doc in docs {
                messages.append(self.getMessage(documentSnapshot: doc))
            }
            completion(messages)
        })
    }
    
    func listenToNewMessages(chatID: String, completion: @escaping ([Message])->()) {
        let messagesRef = db.collection("chats").document(chatID).collection("messages").order(by: "timestamp", descending: false)
        
        messagesRef.addSnapshotListener { (snap, error) in
            
            guard let snap = snap else { return}
            
            var messages = [Message]()
            
            snap.documentChanges.forEach({ (diff) in
                switch diff.type {
                case .added:
                    messages.append(self.getMessage(documentSnapshot: diff.document))
                case .modified:
                    print("message modified")
                case .removed:
                    print("message removed")
                }
                
                completion(messages)
            })
        }
    }
    
    func send(chatID: String, message: Message) {
        let messageRef = db.collection("chats").document(chatID).collection("messages").document()
        
        let text: String
        
        switch message.kind {
        case .text(let str):
            text = str
        default:
            text = ""
        }
        
        let payload: [String:Any] = [
            "timestamp" : Timestamp(),
            "username" : currentUser?.username ?? "",
            "text" : text
        ]
        
        messageRef.setData(payload)
    }
    
    func userIsTyping(chatID: String, username: String, isTyping: Bool) {
        rtdb.child("chats").child(chatID).child("users").child(username).child("is_typing").setValue(isTyping)
    }
    
    func observeIfUserIsTyping(chatID: String, username: String, completion: @escaping (Bool)->()) {
        rtdb.child("chats").child(chatID).child("users").child(username).child("is_typing")
            .observe(.value) { (snap) in
                print("observeIfUserIsTyping")
                let isTyping = snap.value as? Bool
                completion(isTyping ?? false)
        }
    }
}

