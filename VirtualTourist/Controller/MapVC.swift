//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    //MARK:- Global Variables
    private let regionKey = "region"
    var annotations: [MKPointAnnotation]!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var newPin: Pin!
    var selectedCoordinate: CLLocationCoordinate2D!

    
    var pinObserverToken: Any!
    
    //MARK:- Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    //MARK:- LifeCycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        loadStoredRegion()
        addGestureRecognizer()
        setUpFetchedResultsController()
        loadAnnotations()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
        mapView.region.save(to: UserDefaults.standard, with: regionKey)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "pinTapped") {
            let albumVC = segue.destination as! AlbumVC
            let pin = sender as! Pin
            albumVC.pin = pin
            albumVC.dataController = self.dataController
        }
    }
    
    fileprivate func loadStoredRegion() {
        if let region = mapView.region.load(from: UserDefaults.standard, with: regionKey) {
            mapView.region = region
        } else {
            print("First time loading app")
        }
    }
    

    func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func loadAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(pin.annotation())
                }
            }
        }
    }
    
    //MARK:- MapView Delegate functions
    
    // On selecting a pin the data is passed to the AlbumVC which is then called. The pin must be deselected or it will be unresponsive on returning to the MapVC.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let coordinate = view.annotation?.coordinate {
            do {
                try fetchedResultsController.performFetch()
            } catch {
                fatalError("The fetch could not be performed: \(error.localizedDescription)")
            }
            if let pins = fetchedResultsController.fetchedObjects {
                for pin in pins {
                    if pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude {
                        let selectedPin = pin
                        mapView.deselectAnnotation(view.annotation, animated: false)
                        self.performSegue(withIdentifier: "pinTapped", sender: selectedPin)
                    }
                }
            }
        }
    }
    
    // Controls the appearance and behaviour of annotation objects
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    //MARK:- Actions
    
    @objc func longTap(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            
            // convert point of touch to coordinate in mapview
            let pointInView = sender.location(in: mapView)
            let pointOnMap = mapView.convert(pointInView, toCoordinateFrom: mapView)
            selectedCoordinate = pointOnMap
            mapView.setCenter(mapView.centerCoordinate, animated: false)
            let coordinateDouble = [pointOnMap.latitude, pointOnMap.longitude]
            NetworkClient.getPhotosRequest(coordinate: coordinateDouble, pageNo: 1, completion: self.handleGetPhotosRequest(result:))
        }
    }
    
    
    func handleGetPhotosRequest(result: Result<PhotosResponse, Error>) {
        switch result {
        case .failure:
            Alert.showGetPhotosFailure(on: self)
        case .success(let response):
            print(response.photos.pages)
            addPin(coordinate: selectedCoordinate, totalPages: response.photos.pages)
            NetworkClient.getImageForPhotoRequest(response: response, completion: handleImageForPhotoResponse(result:))
            
        }
    }
    
    func addPhotos(_ data: (Data)) {
        let viewContext = dataController.viewContext
        let photo = Photo(context: viewContext)
        photo.image = data
        photo.creationDate = Date()
        photo.pin = newPin
        try? viewContext.save()
    }
    
    func handleImageForPhotoResponse(result: Result<Data, Error>) {
        switch result {
        case .failure(let error):
            print(error.localizedDescription)
        case .success(let data):
            addPhotos(data)
        }
    }

    
    // Saves pin to persistent store
    func addPin(coordinate: CLLocationCoordinate2D, totalPages: Int) {
        let viewContext = dataController.viewContext
        viewContext.perform {
            let pin = Pin(context: viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            pin.totalPages = Int32(totalPages)
            try? viewContext.save()
            self.newPin = pin
            self.mapView.addAnnotation(pin.annotation())
        }
    }
}

//MARK:- Notifications and gesture recognizers

extension MapVC {
    
    func addGestureRecognizer() {
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        self.view.addGestureRecognizer(longTapGesture)
    }
}

