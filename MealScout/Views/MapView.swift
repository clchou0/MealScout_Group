//
//  MapView.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State var viewModel: MapViewModel = MapViewModel()
    @State var mapItems: [String: MKMapItem] = [:]
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        mapComponent
        .overlay(alignment: .bottom) {
            buttonsSection.offset(x: 0, y: -80)
        }
        .sheet(isPresented: $viewModel.presentRestaurantSheet, onDismiss: {
            viewModel.selectedFeature = nil
        }) {
            if let item = viewModel.mapItem {
                RestaurantSheet(mapItem: item)
                    .cornerRadius(0)
                    .presentationDetents([.large])
            }
        }
        .onAppear() {
            viewModel.reloadAllReviews()
            print("Reviews: \(viewModel.allReviews.count)")
            viewModel.reloadFilteredRestaurants()
            Task { await viewModel.checkForSharedPlace() }
        }
        .onChange(of: scenePhase) { _, phase in
            Task {
                if phase == .active { await viewModel.checkForSharedPlace() }
            }
        }
        
        .sheet(isPresented: $viewModel.presentFilterSheet) {
            FiltersSheet(filter: $viewModel.filter)
        }
        .onChange(of: viewModel.presentFilterSheet) { _, newValue in
            // Detect if the filter sheet has been collapsed
            if !newValue {
                viewModel.reloadFilteredRestaurants()
                print("restaurants loaded: \(viewModel.filteredRestaurants.count)")
            }
        }
        .sheet(isPresented: $viewModel.presentResultsSheet) {
            FilterResultsSheet(delegate: { id in
                viewModel.goToRestaurant(id: id)
            },
            filteredRestaurants: viewModel.filteredRestaurants)
        }
        .resultAlert(alertItem: $viewModel.alertItem)
    }
    
    var mapComponent: some View {
        Map(position: $viewModel.position, selection: $viewModel.selectedFeature) {
            UserAnnotation()
            
            ForEach(viewModel.filteredRestaurants) { restaurant in
                if let item = mapItems[restaurant.id.rawValue] {
                    let coord = item.location.coordinate
                    
                    Annotation(restaurant.name, coordinate: coord, anchor: .bottom) {
                        VStack(spacing: 0) {
                            // Pin Head (Bubble)
                            ZStack {
                                Circle()
                                    .fill(.purple)
                                    .frame(width: 20, height: 20)
                                
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            // Pin Pointer (Needle Tip)
                            Image(systemName: "triangle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 8, height: 6)
                                .foregroundStyle(.purple)
                                .rotationEffect(.degrees(180))
                                .offset(y: -1) // Closes seam with circle
                            
                            // Ground Shadow
                            Ellipse()
                                .fill(.black.opacity(0.2))
                                .frame(width: 14, height: 4)
                                .offset(y: 1)
                        }
                        .onTapGesture {
                            viewModel.mapItem = item
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .including([.restaurant])))
        .mapControls {
            MapUserLocationButton()
        }
        .onChange(of: viewModel.selectedFeature) { _, newValue in
            guard let feature = newValue else { return }
            
            guard let category = feature.pointOfInterestCategory else { return }
            guard FetchMapItem.foodCategories.contains(category) else { return }
            viewModel.handleChangeFeature(feature: feature)
        }
        .onChange(of: viewModel.mapItem) { _, newValue in
            if let newItem = newValue {
                viewModel.handleChangeMapItem(mapItem: newItem)
            }
        }
        .task(id: viewModel.filteredRestaurants) {
            for restaurant in viewModel.filteredRestaurants {
                let idString = restaurant.id.rawValue
                if let mapItem = await FetchMapItem.getByString(from: idString) {
                    mapItems[idString] = mapItem
                }
            }
        }
    }
    
    var buttonsSection: some View {
        HStack {
            Button {
                viewModel.presentFilterSheet = true
            } label: {
                Text("Filter").font(.system(size: 20))
            }
            .contentShape(Rectangle())
            .frame(width: 150)
            
            Rectangle()
                .fill(.black)
                .frame(width: 0.5)
            
            Button {
                viewModel.presentResultsSheet = true
            } label: {
                Text("Results").font(.system(size: 20))
            }
            .contentShape(Rectangle())
            .frame(width: 150)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.gray)
        .background(.white)
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(.black.opacity(0.4), lineWidth: 1.5)
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    MapView()
}
