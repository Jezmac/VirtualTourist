//
//  AlbumVC.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import UIKit
import MapKit
import CoreData

class AlbumVC: UIViewController, MKMapViewDelegate {

    
    @IBOutlet weak var zoomMapView: MKMapView!
    @IBOutlet weak var imageCollection: UICollectionView!
    @IBOutlet weak var newCollectionButton: CustomButton!
    
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var diffableDataSource: UICollectionViewDiffableDataSource<String, NSManagedObjectID>!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        zoomMapView.delegate = self
        navigationController?.isNavigationBarHidden = false
        navigationItem.backBarButtonItem?.title = "Back"
        mapManager(mapView: zoomMapView)
        imageCollection.contentMode = .scaleAspectFill
        setupCollectionViewDataSource()
    }
    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
        setupNewCollectionButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    
    private func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupNewCollectionButton() {
        print(pin.totalPages)
        if pin.totalPages == 1 {
            newCollectionButton.isEnabled(false)
            newCollectionButton.setTitle("All Images Loaded For Location", for: .normal)
        }
        else if fetchedResultsController.fetchedObjects == [] {
            newCollectionButton.isEnabled(false)
            newCollectionButton.setTitle("No Images For Location", for: .normal)
        } else {
            newCollectionButton.setTitle("New Collection", for: .normal)
        }
    }
    
    // Diffable datasource is the new delegate protocol for automatically animating changes in a collection view when its datasource changes.
    private func setupCollectionViewDataSource() {
        diffableDataSource = UICollectionViewDiffableDataSource<String, NSManagedObjectID>(collectionView: imageCollection) { (collectionView, indexPath, objectID) -> UICollectionViewCell? in
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
            
            let aPhoto = self.fetchedResultsController.object(at: indexPath)
            
            
            if aPhoto.image == nil {
                self.newCollectionButton.isEnabled(false)
                cell.imageView.backgroundColor = ColorPalette.udacityBlue.withAlphaComponent(0.5)
                cell.activityIndicator.startAnimating()
                
                DispatchQueue.global(qos: .background).async {
                    if let imageData = try? Data(contentsOf: aPhoto.imageURL!) {
                        DispatchQueue.main.async {
                            let viewContext = self.dataController.viewContext
                            aPhoto.image = imageData
                            try? viewContext.save()
                            cell.imageView.backgroundColor = .white
                            cell.imageView.image = UIImage(data: imageData)
                            cell.activityIndicator.stopAnimating()
                        }
                    }
                }
            } else {
                if let imageData = aPhoto.image {
                    cell.imageView.backgroundColor = .white
                    cell.imageView.image = UIImage(data: imageData)
                    cell.activityIndicator.stopAnimating()
                }
                if self.newCollectionButton.currentTitle == "New Collection" {
                    self.newCollectionButton.isEnabled(true)
                }
            }
            return cell
        }
    }
    
    
    func mapManager(mapView: MKMapView) {
        let annotation = pin.annotation()
        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        mapView.selectAnnotation(annotation, animated: true)
        mapView.isUserInteractionEnabled = false
    }
    
    // Controls the appearance and behaviour of annotation objects
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    func deletePhoto(at indexPath: IndexPath) {
        let viewContext = dataController.viewContext
        viewContext.performAndWait {
            let photoToDelete = self.fetchedResultsController.object(at: indexPath)
            print(photoToDelete)
            viewContext.delete(photoToDelete)
            try? viewContext.save()
        }
    }
    @IBAction func newCollectionTapped(_ sender: Any) {
        if let photos = fetchedResultsController.fetchedObjects {
            let viewContext = dataController.viewContext
            for photo in photos.reversed() {
                viewContext.perform {
                    viewContext.delete(photo)
                }
                try? viewContext.save()
            }
            let page = min(pin.totalPages, 4000/30)
            let randomPage = Int(arc4random_uniform(UInt32(page)) + 1)
            print("page: \(randomPage)")
            NetworkClient.getPhotosRequest(pin: pin, pageNo: randomPage, dataController: dataController) { result in
                
            }
        }
    }
}
    

extension AlbumVC: UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widthRowOfThree = collectionView.bounds.width / 3.0 - 1
        let height = widthRowOfThree
        return CGSize(width: widthRowOfThree, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deletePhoto(at: indexPath)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.diffableDataSource.apply(snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>, animatingDifferences: true)
    }
}
