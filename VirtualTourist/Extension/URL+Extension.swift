//
//  URL+Extension.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 28/03/2021.
//  This extension is based on an implementation by Bhuvan Bhatt on Jun 22 '18 at 14:43
// it can be found at: https://stackoverflow.com/questions/34060754/how-can-i-build-a-url-with-query-parameters-containing-multiple-values-for-the-s


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
