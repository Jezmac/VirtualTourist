//
//  NetworkClient.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 12/03/2021.
//

import Foundation

class NetworkClient {
    
    let Authkey = "911bebfe2a9beb397796a7fb3f02febd"
    let secret = "b661c8eea9ef884f"
    
    // This is the url with geo context as limiting factor. adds latitude and longitude queries.
    
    let url = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=911bebfe2a9beb397796a7fb3f02febd&geo_context=2&lat=1.0&lon=1.0&format=rest"
}
