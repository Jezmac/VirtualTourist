//
//  NetworkClient.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import Foundation
import UIKit

class NetworkClient {
    
    let secret = "b661c8eea9ef884f"
    
    
    // Generates URLs for the 2 main requests.  Using a coordinate array to get the photoResponse and passing in a photo struct when the call to getImageForPhoto is made.
    
    enum Endpoints {
        
        static let base = "https://www.flickr.com/services/rest/"
        static let key = "911bebfe2a9beb397796a7fb3f02febd"
        
        
        case getPhotos(Pin)
        case getImageForPhoto(PhotoStruct)
        
        var stringValue: String {
            switch self {
            case .getPhotos(let pin): return "\(Endpoints.base)?method=flickr.photos.search&api_key=\(Endpoints.key)&geo_context=2&lat=\(pin.coordinate()[0])&lon=\(pin.coordinate()[1])&radius=0.1&per_page=30&format=json&nojsoncallback=1&bbox=\(pin.coordinate()[1]-0.1),\(pin.coordinate()[0]-0.1),\(pin.coordinate()[1]+0.1),\(pin.coordinate()[0]+0.1)"
            case .getImageForPhoto(let photo): return "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_m.jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    // This is the generic get request function
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping (Result<ResponseType, ErrorType>) -> Void) {
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, response, error  in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.connection))
                    print("ConnectionFailure")
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let decodedResponse = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedResponse))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decoding))
                    print("Decoding error")
                }
            }
        }.resume()
    }
    
    // This gets a photoResponse from the Flickr API from a pin object.
    class func getPhotosRequest(pin: Pin, pageNo: Int, dataController: DataController, completion: @escaping (Result<PhotosResponse, Error>) -> Void) {
        
        // Use basic URL if no pageNo is provided
        var url = Endpoints.getPhotos(pin).url
        
        // add page parameter if a random value has been given (from newCollectionTapped)
        if pageNo > 1 {
            url = url.appendQuery("page", value: "\(pageNo)")
            print(url)
        }
        taskForGETRequest(url: url, response: PhotosResponse.self) { result in
            print(url)
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                completion(.success(response))
                // add total page count from response to pin entity
                let viewContext = dataController.viewContext
                pin.totalPages = Int32(response.photos.pages)
                try? viewContext.save()
                // create photo entity for each object in response.photos
                for photo in response.photos.photo {
                    let imageURL = Endpoints.getImageForPhoto(photo).url
                    makePhoto(data: nil, imageURL: imageURL, pin: pin, dataController: dataController)
                }
            }
        }
    }
    
    // Creates a photo entity and saves it to the persistent store.
    class func makePhoto(data: Data?, imageURL: URL, pin: Pin, dataController: DataController) {
        let viewContext = dataController.viewContext
        let photo = Photo(context: viewContext)
        photo.creationDate = Date()
        photo.imageURL = imageURL
        photo.image = nil
        photo.pin = pin
        try? viewContext.save()
    }
}
