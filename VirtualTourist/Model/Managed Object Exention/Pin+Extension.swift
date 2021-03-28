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
    
    public func annotation() -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        return annotation
    }
    
    public func coordinate() -> [Double] {
        return [self.latitude, self.longitude]
    }
}
