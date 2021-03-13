//
//  MKCoordinateRegion+Extension.swift
//  VirtualTourist
//
//  Created by Jeremy MacLeod on 13/03/2021.
//

import MapKit

extension MKCoordinateRegion {
    public func save(to defaults: UserDefaults, with Key: String) {
        let regionData = [
            center.latitude,
            center.longitude,
            span.latitudeDelta,
            span.longitudeDelta]
        defaults.set(regionData, forKey: Key)
    }
    
    // load region default, first check if value is present else return a nil. Then use the object as [Double] to build an MKCoordinate region for the mapView.
    public func load(from defaults: UserDefaults, with Key: String) -> MKCoordinateRegion? {
        guard let region = defaults.object(forKey: Key) as? [Double] else { return nil }
        let center = CLLocationCoordinate2D(latitude: region[0], longitude: region[1])
        let span = MKCoordinateSpan(latitudeDelta: region[2], longitudeDelta: region[3])
        return MKCoordinateRegion(center: center, span: span)
    }
}
