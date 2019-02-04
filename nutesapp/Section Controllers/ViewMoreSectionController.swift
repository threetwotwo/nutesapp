//
//  ViewMoreSectionController.swift
//  nutesapp
//
//  Created by Gary Piong on 28/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import Foundation
import IGListKit
import FirebaseFirestore

final class ViewMoreSectionController: ListSectionController {
    
    //MARK: - Variables

    var viewMore: ViewMore?
    var button: UIButton!
    //flag to stop get duplicate calls when reusing cells
    //sets to true when getReplyCount callback is finished
    var hasUpdated: Bool = true
    let firestore = FirestoreManager.shared
    
    var cachedComments = [Comment]()
    var lastCommentSnapshot: DocumentSnapshot?
    
    var collapsed: Bool?

    override func didUpdate(to object: Any) {
        precondition(object is ViewMore)
        self.viewMore = object as? ViewMore
    }
    
    override func numberOfItems() -> Int {
        return 1
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        guard let width = collectionContext?.containerSize.width else {fatalError()}
        return CGSize(width: width, height: 55)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        
        guard let viewModel = viewMore,
            let context = collectionContext else { fatalError() }
        
        let identifier: String
        let buttonTitle: String
        
        identifier = viewModel.type == .root ? "commentViewMore" : "replyViewMore"
        buttonTitle = viewModel.type == .root ? "View previous replies (\(self.viewMore?.count ?? 0))" : "View more"

        let cell = context.dequeueReusableCellFromStoryboard(withIdentifier: identifier, for: self, at: index) as? ViewMoreCell
        
        cell?.delegate = self
        
        cell?.viewMoreButton.setTitle(buttonTitle, for: [])
        self.button = cell?.viewMoreButton
        cell?.loadingindicator.isHidden = true
        cell?.loadingindicator.stopAnimating()
        return cell ?? UICollectionViewCell()
    }
    
}

//MARK: - ViewMoreCellDelegate

extension ViewMoreSectionController: ViewMoreCellDelegate {
    func viewMoreTapped(cell: ViewMoreCell) {
        guard let vc = viewController as? CommentViewController else { return }
        
        let index = vc.collectionView.indexPath(for: cell)?.section ?? 0
        
        guard self.collapsed == nil  else {

            if self.collapsed! {
                vc.items.insert(contentsOf: cachedComments, at: index + 1)
            } else {
                if !cachedComments.isEmpty {
                    vc.items.removeSubrange(index+1...index+cachedComments.count)
                }
            }
            
            self.collapsed = !self.collapsed!

            vc.adapter.performUpdates(animated: true, completion: nil)
            
            let buttonTitle = collapsed! ? "Show all replies" : "Hide replies"
            cell.viewMoreButton.setTitle(buttonTitle, for: [])
            return
        }
        
        guard hasUpdated else { return }
        
        self.hasUpdated = false
        cell.loadingindicator.isHidden = false
        cell.loadingindicator.startAnimating()

        firestore.getReplies(postID: viewMore?.comment.postID ?? "", parentID: viewMore?.comment.id ?? "", limit: 3, after: lastCommentSnapshot) { (comments, lastSnap)  in
            //if no comments left to retrieve
            guard comments.count > 0 else {
                cell.viewMoreButton.setTitle("Hide replies", for: [])
                self.collapsed = false
                self.hasUpdated = true
                cell.loadingindicator.isHidden = true
                cell.loadingindicator.stopAnimating()
                return
            }
            
            let viewMore = ViewMore(comment: (self.viewMore?.comment)!, type: .root, count: (self.viewMore?.count)! - comments.count)
            
            self.lastCommentSnapshot = lastSnap
            self.cachedComments.append(contentsOf: comments)
            
            vc.items.insert(contentsOf: comments, at: vc.items.index(after: index))
            vc.items[index] = viewMore
            
            vc.adapter.performUpdates(animated: true, completion: nil)
            
            self.hasUpdated = true
            cell.loadingindicator.isHidden = true
            cell.loadingindicator.stopAnimating()

        }
        
    }
}
