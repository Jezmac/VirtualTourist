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
        let coordinate = [annotation.latitude, annotation.longitude]
        let clCoordinate = CLLocationCoordinate2D(latitude: coordinate[0], longitude: coordinate[1])
        NetworkClient.getPhotosRequest(coordinate: coordinate, completion: handleGetPhotosRequest(result:))
        
        let newPin = MKPointAnnotation()
        newPin.coordinate = clCoordinate
        mapView.addAnnotation(newPin)
        mapView.setCenter(clCoordinate, animated: true)
        let region = MKCoordinateRegion(center: clCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.setRegion(region, animated: true)
        mapView.selectAnnotation(newPin, animated: true)
        
    }
    
    func handleGetPhotosRequest(result: Result<PhotosResponse, Error>) {
        switch result {
        case .failure:
            Alert.showGetPhotosFailure(on: self)
        case .success(let response):
            print(response.photos.page)
        }
    }

}
