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

    
    
    //MARK:- LifeCycleFunctions
    
    // Region has an extension containing a load function to keep the view controller clean.
    private func loadStoredRegion() {
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
    
    // Clears all annotations and loads all those fecthed from the persistent store
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
    
    // Segue to albumVC and pass the selected pin object plus dataController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "pinTapped") {
            let albumVC = segue.destination as! AlbumVC
            let pin = sender as! Pin
            albumVC.pin = pin
            albumVC.dataController = self.dataController
        }
    }
    
    
    //MARK:- MapView Delegate functions
    
    // On selecting a pin the data is passed to the AlbumVC which is then called. The pin must be deselected or it will be unresponsive on returning to the MapVC.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        if let coordinate = view.annotation?.coordinate {
            do {
                try fetchedResultsController.performFetch()
            } catch {
                fatalError("The fetch could not be performed: \(error.localizedDescription)")
            }
            testForMatchingPin(coordinate)
        }
    }
    
    
    // Checks all pins in fetchedObjects against the coordinate of the selected pin if they match then the segue in performed and the matching pin is the sender
    private func testForMatchingPin(_ coordinate: CLLocationCoordinate2D) {
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                if pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude {
                    self.performSegue(withIdentifier: "pinTapped", sender: pin)
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
    
    
    //MARK:- Actions and related functions
    
    @objc func longTap(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            
            // convert point of touch to coordinate in mapview
            let pointInView = sender.location(in: mapView)
            let pointOnMap = mapView.convert(pointInView, toCoordinateFrom: mapView)
            addPin(coordinate: pointOnMap)
            mapView.setCenter(mapView.centerCoordinate, animated: false)
        }
    }

    
    // Saves pin to persistent store. totalPages is set to 1 until the Flickr response provides the necessary data. The call to Flickr is made as sson as the pin is created.
    func addPin(coordinate: CLLocationCoordinate2D) {
        let viewContext = dataController.viewContext
        viewContext.perform {
            let pin = Pin(context: viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            pin.totalPages = 1
            try? viewContext.save()
            self.newPin = pin
            self.mapView.addAnnotation(pin.annotation())
            NetworkClient.getPhotosRequest(pin: pin, pageNo: 1, dataController: self.dataController) { result in
            }
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

