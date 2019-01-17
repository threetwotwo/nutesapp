//
//  FeedSectionController.swift
//  nutesapp
//
//  Created by Gary Piong on 14/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit

class FeedSectionController: ListBindingSectionController<Post>, ListBindingSectionControllerDataSource, ActionCellDelegate {
    
    //MARK: - Variables

    let firestore = FirestoreManager.shared
    
    var likeCount: Int?
    var didLike: Bool?
    
    func didTapHeart(cell: ActionCell) {
        
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
    
    func didTapComment(cell: ActionCell) {
        print("didTapComment")
        guard let post = object
            ,let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "commentVC") as? CommentViewController else { return }
        vc.items = post.comments
        
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    override init() {
        super.init()
        dataSource = self
    }
    
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
        guard let object = object as? Post else { fatalError() }
        
        let results: [ListDiffable] = [
            PostHeaderViewModel(postId: object.id, username: object.username, timestamp: object.timestamp, url: ""),
            ImageViewModel(url: object.postURL),
            ActionViewModel(likes: likeCount ?? object.likeCount, followedUsernames: object.followedUsernames, didLike: didLike ?? object.didLike)
            ]
        
        return results
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
        case is Comment:
            identifier = "postComment"
        default:
            identifier = "postComment"
        }
        
        let cell = context.dequeueReusableCellFromStoryboard(withIdentifier: identifier, for: self, at: index)
        
        if let cell = cell as? ActionCell {
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
        case is Comment:
            height = 55
        default:
            height = 55
        }
        
        return CGSize(width: width, height: height)
    }
    
    override func didSelectItem(at index: Int) {
        
        guard let post = object
            ,let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserVC") as? UserViewController else { return }
        
        viewController?.navigationController?.pushViewController(vc, animated: true)
        
    }
}
