//
//  CommentViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 14/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit
import Firebase

class CommentViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var commentTextFieldBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var replyingToView: UIView!
    @IBOutlet weak var replyingToLabel: UILabel!
    
    fileprivate func resetCommentTextField() {
        replyingToView.isHidden = true
        commentTextField.text = ""
        replyIndex = nil
    }
    
    @IBAction func cancelReplyButton(_ sender: Any) {
        resetCommentTextField()
    }
    
    //MARK: - Variables
    var parentVC: UIViewController?
    var postIndex: Int?
    var post: Post?
    var items: [ListDiffable] = []
    var firestore = FirestoreManager.shared
    
    //Section number
    var replyIndex: Int?
    //Comment that is being replied to
    var replyingTo: Comment?
    
    //Pagination
    let spinToken = "spinner"
    var lastSnapshot: DocumentSnapshot?
    var loading = false
    
    //MARK: - Adapter
    
    lazy var adapter: ListAdapter = {
        let updater = ListAdapterUpdater()
        let adapter = ListAdapter(updater: updater, viewController: self, workingRangeSize: 1)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
        return adapter
    }()
    
    //MARK: - Load Comments
    
    func loadComments(completion: ()->()) {
//        loading = true
//        self.adapter.performUpdates(animated: true)

        firestore.getComments(postID: post?.id ?? "", limit: 10, after: lastSnapshot) { (comments, lastSnap)  in
            
            guard !comments.isEmpty else {
                self.loading = false
                self.adapter.performUpdates(animated: true)
                return
            }
            
            self.items.append(contentsOf: comments)
            self.lastSnapshot = lastSnap
            self.loading = false
            self.adapter.performUpdates(animated: true)
        }
    }

    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadComments {
        }
        replyingToView.isHidden = true
        self.adapter.performUpdates(animated: true)
        commentTextField.delegate = self
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardNotification(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }
    
    //MARK: - Keyboard
    
    @objc fileprivate func showKeyboard(_ notification: (Notification)) {
        
        UIView.animate(withDuration: 0.3) {
            guard let userInfo = notification.userInfo,
                let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue) else {return}
            let frame = keyboardSize.cgRectValue
            self.commentTextFieldBottomConstraint.constant = frame.height
            
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardNotification(_ notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame?.origin.y ?? 0
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            guard let barHeight = tabBarController?.tabBar.frame.height else {
                return
            }
            if endFrameY >= UIScreen.main.bounds.size.height {
                self.commentTextFieldBottomConstraint?.constant = 0.0
            } else {
                self.commentTextFieldBottomConstraint?.constant = (endFrame?.size.height ?? 0.0) - barHeight
            }
            if notification.name == UIResponder.keyboardWillHideNotification {
                collectionView.contentInset = UIEdgeInsets.zero
            } else {
                collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: endFrame!.height, right: 0)
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0.10),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
        
    }
    
    //UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let comment: Comment
        
        let username = firestore.currentUser.username
        let timestamp = Timestamp()
        let commentID = "\(username)_\(timestamp.seconds)"
        
        if replyingTo != nil {
            //if replying to a reply, set its parentID to the reply's root comment
            let parentID = replyingTo?.parentID == nil ? replyingTo?.id : replyingTo?.parentID
            comment = Comment(parentID: parentID, commentID: commentID, postID: post?.id ?? "", username: username, text: textField.text!, likes: 0, timestamp: timestamp, didLike: false)            
        } else {
            comment = Comment(parentID: nil, commentID: commentID, postID: post?.id ?? "", username: username, text: textField.text!, likes: 0, timestamp: timestamp, didLike: false)
        }
        
        firestore.comment(comment: comment, post: post!, text: textField.text!)

        
        if let index = replyIndex {
            items.insert(comment, at: items.index(after: index))
        } else {
            items.append(comment)
            if collectionView.numberOfSections > 0 {
                let lastSectionIndex = collectionView.numberOfSections - 1 // last section
                let lastRowIndex = collectionView.numberOfItems(inSection: lastSectionIndex) - 1 // last row
                collectionView.scrollToItem(at: IndexPath(row: lastRowIndex, section: lastSectionIndex), at: .bottom, animated: true)
            }
        }
        
        if let parentVC = self.parentVC as? FeedViewController,
            let index = postIndex,
            let post = parentVC.items[index] as? Post{
            //replace old post with new post
            parentVC.items[index] = Post(post: post, newComment: comment)
            parentVC.performUpdates()
        }
        
        replyIndex = nil
        replyingTo = nil
        
        adapter.performUpdates(animated: true, completion: nil)
        textField.resignFirstResponder()
        resetCommentTextField()
        return true
    }
    
}

//MARK: - ListAdapterDataSource

extension CommentViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        var objects = items as [ListDiffable]
        
        if loading {
            objects.append(spinToken as ListDiffable)
        }
        
        return objects
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        switch object {
        case is String:
            return spinnerSectionController()
        case is Comment:
            return CommentSectionController()
        case is ViewMore:
            return ViewMoreSectionController()
        default:
            return ListSectionController()
        }
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
}

extension CommentViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !loading && distance < 200 {
            loading = true
            loadComments {
                
            }
            adapter.performUpdates(animated: true)
        }
    }
}
