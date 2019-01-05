//
//  EditViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

class EditViewController: UIViewController, UITextViewDelegate {
    
    //MARK: - IBOutlets
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var hideKeyboardButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var keyboardViewHeight: NSLayoutConstraint!
    @IBOutlet weak var doneButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIView!
    
    //MARK: - Variables
    let firestore = FirestoreManager.shared
    
    //MARK: - IBActions
    @IBAction func cancelButtonTapped(_ sender: Any) {
        textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func hideKeyboardButtonTapped(_ sender: UIButton) {
        hideKeyboard { (_) in
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        guard let text = self.textView.text,
            text.count > 0 else {return}
        doneButton.isEnabled = false
        hideKeyboard { (_) in
            UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, false, 0.0)
            
            self.imageView.drawHierarchy(in: self.imageView.bounds, afterScreenUpdates: true)
            
            guard let image = UIGraphicsGetImageFromCurrentImageContext() else {return}
            
            UIGraphicsEndImageContext()
            
            
            if let imageData = image.jpegData(compressionQuality: 1) {
                self.firestore.createPost(imageData: imageData)
            }
            
            
//            let username = self.firestore.currentUser.username
            
            //Create unique id
//            let timestamp = FieldValue.serverTimestamp()
//            let postID = "\(username)\(Timestamp.init().seconds)"
//            //Create reference to Cloud Storage
//            let imageRef = Storage.storage().reference().child(postID + ".jpg")
//            imageRef.putData(imageData, metadata: nil) { (metadata, error) in
//
//                imageRef.downloadURL(completion: { (downloadURL, error) in
//                    guard error == nil else {
//                        print(error?.localizedDescription ?? "Error uploading")
//                        return
//                    }
//                    let counter = self.firestore.db.collection("postLikesCounters").document(postID)
//                    self.firestore.createPostLikesCounter(ref: counter, numShards: 1)
//
//                    self.firestore.db.runTransaction({ (transaction, errorPointer) -> Any? in
//
//                        return nil
//                    }, completion: { (object, error) in
//                        if error != nil {
//                            print(error?.localizedDescription)
//                        }
//                    })
//
//                    if let url = downloadURL?.absoluteString {
//                        let db = FirestoreManager.shared.db
//
//                        db!.collection("posts").document(postID).setData([
//                            "uid" : FirestoreManager.shared.currentUser.uid,
//                            "username" : username,
//                            "imageURL" : url,
//                            "timestamp" : timestamp,
//                            "likes" : 0
//                        ]){
//                            error in
//                            guard error == nil else {
//                                print(error?.localizedDescription ?? "Error adding document")
//                                return
//                            }
//
//                            print("post added with ID: \(username)")
//
//                            //notifies the app that a post has been uploaded to cloud storage
//                            //                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "postuploadsuccess"), object: nil)
//                            //increment user's post count
//                            let user = db!.collection("users").document(username)
//                            user.getDocument { (document, error) in
//                                guard let document = document,
//                                    let postCount = document.get("posts") as? Int else {
//                                        print("Document does not exist")
//                                        return
//                                }
//                                user.updateData(["posts" : postCount + 1])
//                            }
//                        }
//                    }
//                })
//            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Keyboard functions

    fileprivate func hideKeyboard(completion: ((Bool)->())? = nil) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.hideKeyboardButton.isHidden = true
            self.doneButtonBottomConstraint.constant = 16
            self.keyboardViewHeight.constant = 0
            self.textView.resignFirstResponder()
            
            self.view.layoutIfNeeded()
            self.textView.alignTextVerticallyInContainer()
            
            //For the bug that cuts off large text text view that is inside a scroll view
            self.textView.isScrollEnabled = false
            self.textView.isScrollEnabled = true


        }, completion: completion)
    }

    fileprivate func showKeyboard(_ notification: (Notification)) {
        
        UIView.animate(withDuration: 0.3) {
            
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                return
            }
            
            let keyboardHeight: CGFloat
            
            if #available(iOS 11.0, *) {
                keyboardHeight = keyboardFrame.cgRectValue.height - self.view.safeAreaInsets.bottom
            } else {
                keyboardHeight = keyboardFrame.cgRectValue.height
            }
            
            //Rearrange buttons
            self.hideKeyboardButton.isHidden = false
            self.doneButtonBottomConstraint.constant = 64
            self.keyboardViewHeight.constant = keyboardHeight
            self.view.layoutIfNeeded()
            
            //Center text
            self.textView.alignTextVerticallyInContainer()
            
            //For large text bug
            self.textView.isScrollEnabled = true

        }
    }
    
    //MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.isEnabled = true
        textView.delegate = self
        self.textView.becomeFirstResponder()

        self.textView.spellCheckingType = .no
        textView.alignTextVerticallyInContainer()
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main) { (notification: Notification) in
            // Any code you put in here will be called when the keyboard is about to display
            print("Show keyboard!")
            self.showKeyboard(notification)
        }
        
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        print("should change text")
//        textView.alignTextVerticallyInContainer()
        return true
    }
}



