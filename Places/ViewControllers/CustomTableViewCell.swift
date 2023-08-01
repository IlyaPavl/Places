//
//  CustomTableViewCell.swift
//  Places
//
//  Created by Ilya Pavlov on 22.07.2023.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var placeImage: UIImageView! {
        didSet {
            placeImage.layer.cornerRadius = placeImage.frame.size.height / 2
        }
    }
    @IBOutlet weak var nameOfPlace: UILabel!
    @IBOutlet weak var locationOfPlace: UILabel!
    @IBOutlet weak var typeOfPlace: UILabel!
    @IBOutlet weak var starsView: RatingControl! {
        didSet {
            starsView.isUserInteractionEnabled = false
        }
    }
    

}
