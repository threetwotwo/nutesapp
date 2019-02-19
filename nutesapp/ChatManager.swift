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

final class ChatManager {
    
    let db = FirestoreManager.shared.db!
    let currentUser = FirestoreManager.shared.currentUser
    
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
    
    func getMessages(chatID: String, completion: @escaping ([Message])->()) {
        let messagesRef = db.collection("chats").document(chatID).collection("messages").order(by: "timestamp", descending: false)
        
        let dsg = DispatchGroup()

        messagesRef.getDocuments(completion: { (snap, error) in
            guard let docs = snap?.documents else { return }
            
            var messages = [Message]()
            
            for doc in docs {
                let data = doc.data()
                let username = data["username"] as? String ?? ""
                let text = data["text"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
                
                let message: Message
                
                if text.isSingleEmoji {
                    message = Message(sender: Sender(id: username, displayName: username), messageID: doc.documentID, timestamp: timestamp.dateValue(), kind: .emoji(text))
                } else {
                    message = Message(sender: Sender(id: username, displayName: username), messageID: doc.documentID, timestamp: timestamp.dateValue(), kind: .text(text))
                }

                
                messages.append(message)
            }
            
            completion(messages)
        })
    }
    
    func send(chatID: String, text: String) {
        let messageRef = db.collection("chats").document(chatID).collection("messages").document()
        let payload: [String:Any] = [
            "timestamp" : Timestamp(),
            "username" : currentUser?.username ?? "",
            "text" : text
        ]
        messageRef.setData(payload)
    }
}

