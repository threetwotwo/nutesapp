//
//  CommentCell.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import IGListKit
import ActiveLabel

protocol CommentCellDelegate: class {
    func didTapHeart(cell: CommentCell)
    func didTapMention(cell: CommentCell, mention: String)
    func didTapHashtag(cell: CommentCell, hashtag: String)
}


class CommentCell: UICollectionViewCell, ListBindable {
    
    weak var delegate: CommentCellDelegate? = nil
    let firestore = FirestoreManager.shared
    
    @IBOutlet weak var commentLabel: ActiveLabel!
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var likeButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        commentLabel.customize { label in
            label.hashtagColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
            label.mentionColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
//            label.URLColor = UIColor(red: 85.0/255, green: 238.0/255, blue: 151.0/255, alpha: 1)
            label.handleMentionTap { self.delegate?.didTapMention(cell: self, mention: $0) }
            label.handleHashtagTap {  self.delegate?.didTapHashtag(cell: self, hashtag: $0) }
            label.handleURLTap {  print($0) }
        }
    }
    
    func bindViewModel(_ viewModel: Any) {
        
        guard let viewModel = viewModel as? CommentViewModel else { return }
        
        //configure button
        likeButton.addTarget(self, action: #selector(onHeart), for: .touchUpInside)
        let imageTitle = viewModel.didLike ? "heart_filled" : "heart_bordered"
        likeButton.setImage(UIImage(named: imageTitle), for: [])
        
        FirestoreManager.shared.getUsername(fromUID: viewModel.username) { (username) in
            self.commentLabel.attributedText = AttributedText.constructComment(username: username, text: viewModel.text)
        }

//        commentTextView.resolveHashTags()
        commentLabel.font = UIFont.systemFont(ofSize: 15)
        
        if let imageView = imageView {
            imageView.layer.cornerRadius = imageView.frame.size.width/2

            firestore.getPhotoURL(uid: viewModel.username) { (url) in
                print("photourl", url)
                imageView.sd_setImage(with: url)
            }
        }

    }
    
    @objc func onHeart() {
        delegate?.didTapHeart(cell: self)
    }
}

extension CommentCellDelegate {
    
    func didTapHeart(cell: CommentCell) {}
    
    func didTapMention(cell: CommentCell, mention: String) {}
    
    func didTapHashtag(cell: CommentCell, hashtag: String) {}
    
}
