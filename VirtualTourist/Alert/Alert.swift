//
//  Alert.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 13/03/2021.
//

import UIKit


//MARK:- Custom alert handler that both allows for specific messages and calls Alert view from outside of ViewControllers

struct Alert {
    
    private static func showBasicAlert(on vc: UIViewController, with title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc.present(alert, animated: true)
    }
    
    static func showGeocodeFailure(on vc: UIViewController) {
        showBasicAlert(on: vc, with: "Could not find location", message: "Debugging Alert")
    }
    
    static func showGetPhotosFailure(on vc: UIViewController) {
        showBasicAlert(on: vc, with: "Could not get photos for this location", message: "Download Failure")
    }
    
    static func showGetImagesFailure(on vc: UIViewController) {
        showBasicAlert(on: vc, with: "Could not get download any images for this location", message: "Download Failure")
    }
}
