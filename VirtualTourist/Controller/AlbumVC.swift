//
//  AlbumVC.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import UIKit
import MapKit

class AlbumVC: UIViewController {

    
    @IBOutlet weak var zoomMapView: MKMapView!
    
    var annotation: AnnotationUnpersistent!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapManager(mapView: zoomMapView)
    }
    
    func mapManager(mapView: MKMapView) {
        let coordinate = CLLocationCoordinate2D(latitude: annotation.latitude, longitude: annotation.longitude)
        let newPin = MKPointAnnotation()
        newPin.coordinate = coordinate
        mapView.addAnnotation(newPin)
        mapView.setCenter(coordinate, animated: true)
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.setRegion(region, animated: true)
        mapView.selectAnnotation(newPin, animated: true)
        
    }

}
