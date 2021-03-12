//
//  CustomButton.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import UIKit


//MARK:- Custom view for UIButtons used in app

class CustomButton: UIButton {
    
    override func awakeFromNib() {
        super .awakeFromNib()
    
    layer.cornerRadius = 5
    layer.borderWidth = 1
    layer.borderColor = ColorPalette.udacityBlue.cgColor
        
    }
    
    // Alternative .isEnabled function that fades button background even if the color is custom
    func isEnabled(_ enabled: Bool) {
        if enabled {
            self.alpha = 1
        } else {
            self.alpha = 0.5
        }
        self.isEnabled = enabled
    }
}
