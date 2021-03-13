//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import UIKit
import MapKit

class MapVC: UIViewController, MKMapViewDelegate {
    
    
    private let regionKey = "region"
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let region = mapView.region.load(from: UserDefaults.standard, with: regionKey) {
            mapView.region = region
        } else {
            print("First time loading app")
        }
    }
    
    deinit {
        mapView.region.save(to: UserDefaults.standard, with: regionKey)
    }
}

