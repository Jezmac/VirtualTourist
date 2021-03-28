//
//  AlbumVC.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import UIKit
import MapKit
import CoreData

class AlbumVC: UIViewController {

    
    @IBOutlet weak var zoomMapView: MKMapView!
    @IBOutlet weak var imageCollection: UICollectionView!
    @IBOutlet weak var newCollectionButton: CustomButton!
    
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var diffableDataSource: UICollectionViewDiffableDataSource<String, NSManagedObjectID>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationItem.backBarButtonItem?.title = "Back"
        mapManager(mapView: zoomMapView)
        imageCollection.contentMode = .scaleAspectFill
        setupCollectionViewDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
        imageCollection.reloadData()
        print(pin.totalPages)
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
    
    private func setupCollectionViewDataSource() {
        diffableDataSource = UICollectionViewDiffableDataSource<String, NSManagedObjectID>(collectionView: imageCollection) { (collectionView, indexPath, objectID) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
            let aPhoto = self.fetchedResultsController.object(at: indexPath)
            
            if aPhoto.image == nil {
                self.newCollectionButton.isEnabled = false
                cell.imageView.backgroundColor = ColorPalette.udacityBlue.withAlphaComponent(0.5)
                cell.activityIndicator.startAnimating()
                
            }
            if let data = aPhoto.image {
                cell.imageView.image = UIImage(data: data)
            } else {
                cell.activityIndicator.startAnimating()
            }
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //print("this is called")
//        let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomPhotoAlbum", for: indexPath) as! PhotoAlbumCustomCell
        
        guard !(self.fetchedResultsController.fetchedObjects?.isEmpty)! else {
            print("images are already present.")
            return photoCell
        }
        
        let photo = self.fetchedResultsController.object(at: indexPath)
        
        if photo.imageData == nil {
            newCollectionButton.isEnabled = false // User cannot interact with it when downloading images
            photoCell.imageOverlay.backgroundColor = UIColor.customColor(red: 242, green: 242, blue: 254, alpha: 0.85)
            photoCell.imageLoadingIndicator.startAnimating()
            DispatchQueue.global(qos: .background).async {
                if let imageData = try? Data(contentsOf: photo.imageURL!) {
                    DispatchQueue.main.async {
                        photo.imageData = imageData
                        do {
                            try self.photoAlbumDataController.viewContext.save()
                        } catch {
                            print("error in saving image data")
                        }
                        let image = UIImage(data: imageData)
                        print("index is : \(indexPath.row)")
                        photoCell.selectedLatLongImage.image = image
                        photoCell.imageOverlay.backgroundColor = UIColor.customColor(red: 255, green: 255, blue: 255, alpha: 0)
                        photoCell.imageLoadingIndicator.stopAnimating()
                    }
                }
            }
        } else {
            if let imageData = photo.imageData {
                let image = UIImage(data: imageData)
                photoCell.selectedLatLongImage.image =  image
                photoCell.imageOverlay.backgroundColor = UIColor.customColor(red: 255, green: 255, blue: 255, alpha: 0)
                photoCell.imageLoadingIndicator.stopAnimating()
            }
        }
        newCollectionButton.isEnabled = true
        return photoCell
    }
    
    
    func mapManager(mapView: MKMapView) {
        let annotation = pin.annotation()
        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        mapView.selectAnnotation(annotation, animated: true)
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
            NetworkClient.getPhotosRequest(coordinate: pin.coordinate(), pageNo: randomPage, completion: self.handleGetPhotosRequest(result:))
        }
    }
    
    func handleGetPhotosRequest(result: Result<PhotosResponse, Error>) {
        switch result {
        case .failure:
            Alert.showGetPhotosFailure(on: self)
        case .success(let response):
            NetworkClient.getImageForPhotoRequest(response: response, completion: self.handleImageForPhotoResponse(result:))
            
        }
    }
    
    func handleImageForPhotoResponse(result: Result<Data, Error>) {
        switch result {
        case .failure(let error):
            print(error.localizedDescription)
        case .success(let data):
            addPhotos(data)
        }
    }
    
    func addPhotos(_ data: (Data)) {
        let viewContext = dataController.viewContext
        let photo = Photo(context: viewContext)
        photo.image = data
        photo.creationDate = Date()
        photo.pin = pin
        try? viewContext.save()
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
