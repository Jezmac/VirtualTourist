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
        
        
        case getPhotos([Double])
        case getImageForPhoto(PhotoStruct)
        
        var stringValue: String {
            switch self {
            case .getPhotos(let coordinate): return "\(Endpoints.base)?method=flickr.photos.search&api_key=\(Endpoints.key)&geo_context=2&lat=\(coordinate[0])&lon=\(coordinate[1])&radius=0.1&per_page=30&format=json&nojsoncallback=1&bbox=\(coordinate[1]-0.1),\(coordinate[0]-0.1),\(coordinate[1]+0.1),\(coordinate[0]+0.1)"
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
    
    // This gets a photoResponse from the Flickr API based on a coordinate pair. This is either the point selected on the map or it comes from a pin object in the AlbumVC.
    class func getPhotosRequest(coordinate: [Double], pageNo: Int, completion: @escaping (Result<PhotosResponse, Error>) -> Void) {
        
        // Use basic URL if no pageNo is provided
        var url = Endpoints.getPhotos(coordinate).url
        
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
                print(response.stat)
            }
        }
    }
    
    // This function gets the photo data for each photo object in a photoResponse. It is called automatically every time a call to flickr is made.
    class func getImageForPhotoRequest(response: PhotosResponse, completion: @escaping (Result<Data, Error>) -> Void) {
        for photo in response.photos.photo {
            URLSession.shared.dataTask(with: Endpoints.getImageForPhoto(photo).url) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                if let data = data {
                    DispatchQueue.main.async {
                        completion(.success(data))
                    }
                }
            }.resume()
        }
    }
    
    class func makeImageURLForPhotoResponse(response: PhotosResponse, completion: @escaping (Result<Data, Error>) -> Void) {
        for photo in response.photos.photo {
            URLSession.shared.dataTask(with: Endpoints.getImageForPhoto(photo).url) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                if let data = data {
                    DispatchQueue.main.async {
                        completion(.success(data))
                    }
                }
            }.resume()
        }
    }
}
