//
//  MapLocationViewModel.swift
//  MealScout
//
//  Created by CLChou on 2026/10/17.
//

import Foundation
import CoreLocation
import UIKit
import SwiftUI

class MapLocationViewModel: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    var isLocationAuthorized: Bool = false
    var currentCoordinate: CLLocationCoordinate2D? {
        locationManager.location?.coordinate
    }
    
    
    override init() {
       super.init()
       locationManager.delegate = self
       locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermissionAccess(
        onAuthorize: @escaping () -> Void,
        onUnauthorized: @escaping (_ alertItem: AlertItem) -> Void
    ){
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .denied, .restricted:
            let alertItem = AlertItem(
                title: "Location access not granted",
                message: "Please enable location permissions in settings to show your current location",
                delegate: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                cancelDelegate: {},
                okLabel: "Open in Settings"
            )
            onUnauthorized(alertItem)
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            onAuthorize()
            break
            
        @unknown default:
            break
        }
    }
    
    
}
