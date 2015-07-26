//
//  LocationService.swift
//  InstaRoulette
//
//  Created by Simen Johannessen on 24/06/15.
//  Copyright © 2015 lomas. All rights reserved.
//

import Foundation
import CoreLocation

struct LocationService {
    typealias SuccessHandler = (address: String) -> Void
    
    static func getLocationAddress(location: CLLocation, successHandler: SuccessHandler) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarkArray, error) -> Void in
            if let placemark = placemarkArray?.last {
                successHandler(address: placemark.name!)
            } else {
                successHandler(address: "Unknown")
            }
        }
    }
}