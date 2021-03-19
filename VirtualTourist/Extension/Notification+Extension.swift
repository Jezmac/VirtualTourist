//
//  Notification+Extension.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 18/03/2021.
//

import Foundation
import CoreData

extension Notification {
    var insertedObjects: Set<NSManagedObject>? {
        return userInfo?.value(for: .insertedObjects)
    }
}
