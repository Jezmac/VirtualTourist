//
//  Pnoto+Extension.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 17/03/2021.
//

import Foundation
import CoreData
import MapKit

extension Pin {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()

    }
    
    // Allows the creation of an annotation for convenience
    public func annotation() -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        return annotation
    }
    
    // Allows for the creation of a coordinate array for convenience and to avoid calling MapKit everywhere.
    public func coordinate() -> [Double] {
        return [self.latitude, self.longitude]
    }
}
