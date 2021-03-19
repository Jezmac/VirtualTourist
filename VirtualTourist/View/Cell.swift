//
//  collectionCell.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 16/03/2021.
//

import UIKit

internal final class Cell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.contentMode = .scaleAspectFill
        imageView.image = nil
    }
}
