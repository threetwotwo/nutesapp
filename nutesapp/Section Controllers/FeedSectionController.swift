//
//  FeedSectionController.swift
//  nutesapp
//
//  Created by Gary Piong on 14/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class FeedSectionController: ListBindingSectionController<Post>, ListBindingSectionControllerDataSource, ActionCellDelegate, ImageCellDelegate {
    
    //MARK: - Variables

    let firestore = FirestoreManager.shared
    
    var likeCount: Int?
    var didLike: Bool?
    
    //MARK: - ImageCellDelegate
    func doubleTapped(cell: ImageCell) {
        likeButtonTapped()
    }
    
    //MARK: - ActionCellDelegate
    
    func didTapLikesLabel(cell: ActionCell) {
        print("didTapLikesLabel")
        
        guard object?.likeCount ?? 0 > 0 else { return }
        
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "searchVC") as? SearchResultsViewController {
            vc.postID = object?.id
            viewController?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func didTapHeart(cell: ActionCell) {
        likeButtonTapped()
    }
    
    func didTapComment(cell: ActionCell) {
        print("didTapComment")
        guard let post = object
            ,let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "commentVC") as? CommentViewController else { return }
        vc.items = Comment.order(comments: post.comments)
        vc.post = post
        vc.parentVC = self.viewController
        vc.postIndex = self.section
        print(section)
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }

    fileprivate func likeButtonTapped() {
        
        self.didLike = !(self.didLike ?? object?.didLike ?? false)
        
        let increment: Int
        
        if didLike ?? true {
            increment = 1
            firestore.like(postID: object?.id ?? "") {
                print("like")
            }
        } else {
            increment = -1
            firestore.unlike(postID: object?.id ?? "") {
                print("unlike")
            }
        }
        
        self.likeCount = (self.likeCount ?? object?.likeCount ?? 0) + increment
        update(animated: true)
    }

    
    //MARK: - init

    override init() {
        super.init()
        dataSource = self
    }
    
    
    //MARK: - ListBindingSectionControllerDataSource

    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
        guard let object = object as? Post else { fatalError() }
        
        let results: [ListDiffable] = [
            PostHeaderViewModel(postId: object.id, username: object.username, timestamp: object.timestamp, url: object.userURL),
            ImageViewModel(url: object.postURL),
            ActionViewModel(likes: likeCount ?? object.likeCount, followedUsernames: object.followedUsernames, didLike: didLike ?? object.didLike, timestamp: object.timestamp)
            ]
        
        var comments = [ListDiffable]()
        
        for comment in object.comments {
            comments.append(CommentViewModel(username: comment.username, text: comment.text, timestamp: comment.timestamp, didLike: comment.didLike))
        }
        
        comments.append(TimestampViewModel(date: object.timestamp))
        
        return results + comments
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, cellForViewModel viewModel: Any, at index: Int) -> UICollectionViewCell & ListBindable {
        
        let identifier: String
        
        guard let context = collectionContext else { fatalError() }
                
        switch viewModel {
            
        case is PostHeaderViewModel:
            identifier = "postHeader"
        case is ImageViewModel:
            identifier = "postImage"
        case is ActionViewModel:
            identifier = "postAction"
        case is CommentViewModel:
            identifier = "postComment"
        case is TimestampViewModel:
            identifier = "postTimestamp"

        default:
            identifier = "postComment"
        }
        
        let cell = context.dequeueReusableCellFromStoryboard(withIdentifier: identifier, for: self, at: index)
        
        if let cell = cell as? ActionCell {
            cell.delegate = self
        }
        
        if let cell = cell as? ImageCell  {
            cell.delegate = self
        }
        
        if let cell = cell as? CommentCell  {
            cell.delegate = self
        }
        
        return cell as! UICollectionViewCell & ListBindable
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, sizeForViewModel viewModel: Any, at index: Int) -> CGSize {
        
        guard let context = collectionContext else { fatalError() }
        
        let width = context.containerSize.width
        let height: CGFloat
        
        switch viewModel {
        case is PostHeaderViewModel:
            height = 55
        case is ImageViewModel:
            height = 250
        case is ActionViewModel:
            height = 110
        case is CommentViewModel:
            height = 35
        case is TimestampViewModel:
            height = 35
        default:
            height = 55
        }
        
        return CGSize(width: width, height: height)
    }
    
    //MARK: - didSelect

    override func didSelectItem(at index: Int) {
        print(index)
        switch index {
        case 0:
            print("header")
            guard   let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Identifier.storyboard.userVC) as? UserViewController else { return }
            let user = User(uid: "", fullname: "", email: "", username: object?.username ?? "", url: object?.userURL ?? "", followerCount: 0)
            vc.user = user
            
            viewController?.navigationController?.pushViewController(vc, animated: true)
        case 1:
            print("image")
        case 2:
            print("action")
        default:
            print("default")
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "commentVC") as? CommentViewController,
                let post = object {
                vc.post = post
                vc.items = Comment.order(comments: post.comments)
                vc.parentVC = self.viewController
                vc.postIndex = self.section
                viewController?.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

//UITextViewDelegate
extension FeedSectionController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print("shouldInteractWith \(URL)")
        if URL.absoluteString.hasPrefix("@") {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userVC") as? UserViewController {
                vc.user = User(username: String(URL.absoluteString.dropFirst()))
                viewController?.navigationController?.pushViewController(vc, animated: true)
            }
        }
        return true
    }
}

//MARK: - CommentCellDelegate

extension FeedSectionController: CommentCellDelegate {
    
    func didTapMention(cell: CommentCell, mention: String) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Identifier.storyboard.userVC) as? UserViewController {
            vc.user = User(username: mention)
            self.viewController?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func didTapHashtag(cell: CommentCell, hashtag: String) {
        print(hashtag)
    }
}
