//
//  Dictionary+Extension.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 18/03/2021.
//

import Foundation
import CoreData


extension Dictionary where Key == AnyHashable {
    func value<T>(for key: NSManagedObjectContext.NotificationKey) -> T? {
        return self[key.rawValue] as? T
    }
}
