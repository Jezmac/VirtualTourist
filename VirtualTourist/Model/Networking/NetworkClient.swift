//
//  NetworkClient.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import Foundation
import UIKit

class NetworkClient {
    
    let AuthKey = "911bebfe2a9beb397796a7fb3f02febd"
    let secret = "b661c8eea9ef884f"
    
    // This is the url with geo context as limiting factor. adds latitude and longitude queries.
    
    enum Endpoints {
        
        static let base = "https://www.flickr.com/services/rest/"
        static let key = "911bebfe2a9beb397796a7fb3f02febd"
        
        
        case getPhotos([Double])
        case getImageForPhoto(PhotoStruct)
        
        var stringValue: String {
            switch self {
            case .getPhotos(let coordinate): return "\(Endpoints.base)?method=flickr.photos.search&api_key=\(Endpoints.key)&geo_context=2&lat=\(coordinate[0])&geo_context=2&lat=\(coordinate[1])&per_page=30&format=json&nojsoncallback=1"
            case .getImageForPhoto(let photo): return "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_m.jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
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
    
    
    class func getPhotosRequest(coordinate: [Double], completion: @escaping (Result<PhotosResponse, Error>) -> Void) {
        taskForGETRequest(url: Endpoints.getPhotos(coordinate).url, response: PhotosResponse.self) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                completion(.success(response))
                print(response.photos.photo.count)
                for photo in response.photos.photo {
                    getImageForPhotoRequest(photo: photo) { result in
                        
                        // Create completion handler that saves images to persistent store
                        switch result {
                        case .failure(let error):
                            print(error.localizedDescription)
                        case .success(let image):
                            print(image)
                        }
                    }
                }
                print(response.stat)
            }
        }
    }
    
    class func getImageForPhotoRequest(photo: PhotoStruct, completion: @escaping (Result<UIImage, ErrorType>) -> Void) {
        URLSession.shared.dataTask(with: Endpoints.getImageForPhoto(photo).url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.image))
                }
                return
            }
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(.success(image))
                }
            }
        }.resume()
    }
}
