//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController, MKMapViewDelegate {
    
    
    private let regionKey = "region"
    
    var pins: [Pin] = []
    
    var annotations: [MKPointAnnotation]!
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    //MARK:- LifeCycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }
    
    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        setUpFetchedResultsController()
        loadStoredRegion()
        addGestureRecognizer()
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.backgroundContext.fetch(fetchRequest) {
            pins = result
            var annotations = [MKPointAnnotation()]
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.title = pin.title
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                annotations.append(annotation)
            }
            DispatchQueue.main.async {
                self.mapView.addAnnotations(annotations)
            }
        }

    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mapView.region.save(to: UserDefaults.standard, with: regionKey)
    }
    
    deinit {
        mapView.region.save(to: UserDefaults.standard, with: regionKey)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "pinTapped") {
            let albumVC = segue.destination as! AlbumVC
            let annotation = sender as! AnnotationUnpersistent
            albumVC.annotation = annotation
            
        }
    }
    
    fileprivate func loadStoredRegion() {
        if let region = mapView.region.load(from: UserDefaults.standard, with: regionKey) {
            mapView.region = region
        } else {
            print("First time loading app")
        }
    }
    
//    func setUpFetchedResultsController() {
//        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
//        let sortDescriptor = NSSortDescriptor(key: "title", ascending: false)
//        fetchRequest.sortDescriptors = [sortDescriptor]
//
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
//        fetchedResultsController.delegate = self
//        do {
//            try fetchedResultsController.performFetch()
//        } catch {
//            fatalError("The fetch could not be performed: \(error.localizedDescription)")
//        }
//    }
    
    //MARK:- MapView Delegate functions
    
    // On selecting a pin the data is passed to the AlbumVC which is then called. The pin must be deselected or it will be unresponsive on returning to the MapVC.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let coordinate = view.annotation?.coordinate {
            let annotation = AnnotationUnpersistent(
                title: (view.annotation?.title ?? "No Location") ?? "",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            mapView.deselectAnnotation(view.annotation, animated: false)
            self.performSegue(withIdentifier: "pinTapped", sender: annotation)
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
            // create annotation for instant pindrop
            let annotation = MKPointAnnotation()
            annotation.coordinate = pointOnMap
            // Use coordinate to create location object for geocoding
            let location = CLLocation(latitude: pointOnMap.latitude, longitude: pointOnMap.longitude)
            // Fix unresponsive map glitch using imperceptible map interaction
            mapView.setCenter(mapView.centerCoordinate, animated: false)
            // call  reverse geocode to obtain locality information
            getPlaceMark(location: location) { result in
                switch result {
                case .failure:
                    Alert.showGeocodeFailure(on: self)
                case .success(let placemark):
                    self.mapView.addAnnotation(annotation)
                    annotation.title = placemark.locality
                    self.addPin(title: placemark.locality ?? "", location: location)
                }
            }
        }
    }
    
    func getPlaceMark(location: CLLocation, completion: @escaping (Result<CLPlacemark, ErrorType>) -> Void) {
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if error != nil {
                DispatchQueue.main.async {
                    completion(.failure(.geocode))
                }
            }
            var placemark: CLPlacemark?
            // Selects first result from geocode if there are more than one.
            if let placemarks = placemarks, placemarks.count > 0 {
                placemark = placemarks.first
            }
            if let placemark = placemark {
                DispatchQueue.main.async {
                    completion(.success(placemark))
                }
            }
        }
    }
    
    // Saves pin to persistent store
    func addPin(title: String, location: CLLocation) {
        let viewContext = dataController.viewContext
        viewContext.perform {
            let coordinate: [Double] = [location.coordinate.latitude, location.coordinate.longitude]
            let pin = Pin(context: viewContext)
            pin.title = title
            pin.latitude = coordinate[0]
            pin.longitude = coordinate[1]
            try? viewContext.save()
        }
    }
}


extension MapVC {
    
    func addGestureRecognizer() {
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        self.view.addGestureRecognizer(longTapGesture)
    }
}

extension MapVC: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
}

