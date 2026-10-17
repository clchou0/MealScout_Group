//
//  MapViewModel.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

import Foundation
import MapKit
import SwiftUI

@Observable
class MapViewModel {
    // TO DO: Set default placement thingy and location to current location (if location access enabled)
    var cameraPosition: MapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    ))
    
    var selectedFeature: MapFeature? = nil
    var presentRestaurantSheet: Bool = false
    var presentFilterSheet: Bool = false
    var presentResultsSheet: Bool = false
    
    var mapItem: MKMapItem? = nil
    var filter = FilterObject()
    let useCase = FilterReviewsUseCase()
    var filteredRestaurants: [Restaurant] = []
    var alertItem: AlertItem? = nil

    var targetLocationCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
    
    init() {
        
    }
    
    func handleChangeFeature(feature: MapFeature) {
        print("Tapped: \(feature.title ?? "unknown")")
        Task {
            guard let mapItem = await FetchMapItem.getByFeature(for: feature) else {
                presentRestaurantSheet = false
                return
            }
            self.mapItem = mapItem
        }
    }
    
    func handleChangeMapItem(mapItem: MKMapItem) {
        print("\(mapItem.name ?? "unknown"): \(mapItem.identifier?.rawValue ?? "unknown")")
        let coord = mapItem.location.coordinate
        print("LAT: \(coord.latitude), LNG: \(coord.longitude)")
        presentRestaurantSheet = true
    }
    
    func reloadFilteredRestaurants() async {
        let result = await useCase.execute(filter: filter)
        switch result {
            case .success(let restaurants): filteredRestaurants = restaurants
            case .failure(let error): print(error)
        }
    }
    
    func goToRestaurant(id: MapIdentifier) {
        Task {
            if let restaurantItem = await FetchMapItem.getByString(from: id.rawValue) {
                mapItem = restaurantItem
                presentResultsSheet = false
            }
        }
    }
    
    // Check the userdefaults field of shared_place_id, to perform changes according to it (central location or a restaurant)
    func checkForSharedPlace() async {
        print("CHECKING")
        guard let id = UserDefaults(suiteName: "group.MealScout")?.string(forKey: "shared_place_id") else {
            print("not found")
            return
        }
        UserDefaults(suiteName: "group.MealScout")?.removeObject(forKey: "shared_place_id")
        print("APP GOT: \(id)" )
        
        Task {
            if let item = await FetchMapItem.getByString(from: id) {
                print("GOT ITEM!!: \(item.name ?? "Unknown")")
                
                if let category = item.pointOfInterestCategory, FetchMapItem.foodCategories.contains(category) {
                    // Is a restaurant, support usage as a location or open the restaurant
                    alertItem = AlertItem(
                        title: "Use restaurant or location",
                        message: "Would you like to use \(item.name ?? "Unknown place") as a restaurant or a location basis?",
                        delegate: { self.mapItem = item },
                        cancelDelegate: {
                            self.targetLocationCoordinate = item.location.coordinate
                        },
                        okLabel: "Restaurant",
                        cancelLabel: "Location"
                    )
                } else {
                    alertItem = AlertItem(
                        title: "Use location",
                        message: "Would you like to use \(item.name ?? "Unknown place") as the target location?",
                        delegate: {
                            self.targetLocationCoordinate = item.location.coordinate
                        },
                        cancelDelegate: { }
                    )
                }
            }
        }
    }
    
    func setTargetAsZoom() {
        if let camera = cameraPosition.camera {
            self.targetLocationCoordinate = camera.centerCoordinate
        } else if let region = cameraPosition.region {
            self.targetLocationCoordinate = region.center
        } else if let rect = cameraPosition.rect {
            self.targetLocationCoordinate = MKCoordinateRegion(rect).center
        } else if let item = cameraPosition.item {
            self.targetLocationCoordinate = item.location.coordinate
        }
    }
}
