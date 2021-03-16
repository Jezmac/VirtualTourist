//
//  SearchResponse.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 15/03/2021.
//

import Foundation

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: String
    let photo: [PhotoStruct]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "perpage"
        case total
        case photo
    }
}

