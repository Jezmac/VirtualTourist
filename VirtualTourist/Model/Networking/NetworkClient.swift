//
//  NetworkClient.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import Foundation

class NetworkClient {
    
    let AuthKey = "911bebfe2a9beb397796a7fb3f02febd"
    let secret = "b661c8eea9ef884f"
    
    // This is the url with geo context as limiting factor. adds latitude and longitude queries.
    
    enum Endpoints {
        
        static let base = "https://www.flickr.com/services/rest/"
        static let key = "911bebfe2a9beb397796a7fb3f02febd"
        
        
        case getPhotos([Double])
        case getImageForPhoto(String)
        
        var stringValue: String {
            switch self {
            case .getPhotos(let coordinate): return "\(Endpoints.base)?method=flickr.photos.search&api_key=\(Endpoints.key)&geo_context=2&lat=\(coordinate[0])&geo_context=2&lat=\(coordinate[1])&format=json&nojsoncallback=1"
            case .getImageForPhoto(let id): return Endpoints.base + id
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
        //    let url = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=911bebfe2a9beb397796a7fb3f02febd&geo_context=2&lat=1.0&geo_context=2&lat=1.0&format=rest"
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
                print(response.stat)
            }
        }
    }
}
