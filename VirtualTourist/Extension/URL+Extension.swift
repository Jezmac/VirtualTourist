//
//  URL+Extension.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 28/03/2021.
//

import Foundation

extension URL {
    
    func appendQuery(_ item: String, value: String?) -> URL {
        
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }
        
        var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        
        let queryItem = URLQueryItem(name: item, value: value)
        
        queryItems.append(queryItem)
        
        urlComponents.queryItems = queryItems
        
        if let url = urlComponents.url {
            
        return url
        } else {
            return absoluteURL
        }
    }
}
