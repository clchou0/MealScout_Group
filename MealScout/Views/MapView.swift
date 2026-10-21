//
//  MapView.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var session = AccountSession()
    @State private var showAccount = false
    @State var viewModel: MapViewModel = MapViewModel()
    @State var mapItems: [String: MKMapItem] = [:]
    @Environment(\.scenePhase) private var scenePhase
    @State var locationManager: MapLocationViewModel = MapLocationViewModel()
    @State var visibleMeters: Double = 0
    
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    
    var body: some View {
        ZStack {
            mapComponent
                .overlay(alignment: .bottom) {
                    operationsButtonsSection.offset(x: 0, y: -80)
                }
            
            HStack {
                VStack {
                    HStack {
                        accountsToolBar
                        Spacer()
                    }
                    .padding(.leading, 16)
                    Spacer()
                }
            }
            
            HStack {
                Spacer()
                VStack {
                    mapButtonsSection
                    Spacer()
                }
            }
            .padding(.top, 80)
            .padding(.trailing, 16)
        }
        .environment(session)
        .sheet(isPresented: $showAccount) {
            AccountView().environment(session)
        }
        .sheet(isPresented: $viewModel.presentRestaurantSheet, onDismiss: {
            viewModel.selectedFeature = nil
            viewModel.mapItem = nil
            Task {
                await viewModel.reloadFilteredRestaurants()
            }
        }) {
            if let item = viewModel.mapItem {
                RestaurantSheet(mapItem: item, targetLocation: viewModel.targetLocationCoordinate)
                    .environment(session)
                    .cornerRadius(0)
                    .presentationDetents([.large])
            }
        }
        .onAppear() {
            Task {
                await viewModel.checkForSharedPlace()
                await viewModel.loadFirebaseData()
            }
            locationManager.requestPermissionAccess(
                onAuthorize: {
                    viewModel.cameraPosition = .userLocation(fallback: .automatic)
                    
                    if let coord = locationManager.currentCoordinate {
                        viewModel.targetLocationCoordinate = coord
                    }
                },
                onUnauthorized: { _ in}
            )
        }
        .onChange(of: scenePhase) { _, phase in
            Task {
                if phase == .active { await viewModel.checkForSharedPlace() }
            }
        }
        
        .sheet(isPresented: $viewModel.presentFilterSheet, onDismiss: {
            Task { await viewModel.reloadFilteredRestaurants() }
        }) {
            FiltersSheet(filter: $viewModel.filter)
        }
        .sheet(isPresented: $viewModel.presentResultsSheet, onDismiss: {
            Task { await viewModel.reloadFilteredRestaurants() }
        }) {
            FilterResultsSheet(delegate: { id in
                viewModel.goToRestaurant(id: id)
            },
                               filteredRestaurants: viewModel.filteredRestaurants)
        }
        .resultAlert(alertItem: $viewModel.alertItem)
    }
    
    var mapComponent: some View {
        MapReader { proxy in
            Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedFeature) {
                UserAnnotation()
                
                ForEach(viewModel.filteredRestaurants) { restaurant in
                    if let item = mapItems[restaurant.id.rawValue] {
                        Annotation(restaurant.name, coordinate: item.location.coordinate, anchor: .bottom) {
                            RestaurantPin()
                                .onTapGesture {
                                    viewModel.mapItem = item
                                }
                        }
                    }
                }
                Annotation("", coordinate: viewModel.targetLocationCoordinate) {
                    TargetPin()
                }
            }
            .mapStyle(.standard(pointsOfInterest: .including([.restaurant])))
            .mapControls {
                HStack {
                    MapCompass()
                }
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
            .onMapCameraChange(frequency: .onEnd) { context in
                self.visibleMeters = context.region.span.latitudeDelta * 111_000
            }
            .onTapGesture { screenPoint in
                let coordinate = proxy.convert(screenPoint, from: .local)
                Task {
                    await viewModel.handleMapTap(coordinate: coordinate, distance: visibleMeters)
                }
            }
        }
    }
    
    var accountsToolBar: some View {
        Button {
            showAccount = true
        } label: {
            Label(
                session.user == nil ? "Log in / Sign up" : "My account",
                systemImage: session.user == nil
                ? "person" : "person.crop.circle.fill"
            )
            .font(.subheadline.weight(.semibold))
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
        }
    }
    
    var mapButtonsSection: some View {
        HStack(spacing: 0) {
            selectModeButton
                .frame(width: 60)
            Divider()
                .frame(height: 24)
            currentLocationButton
                .frame(width: 60)
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
        //        .frame(maxHeight: 40)
    }
    
    var selectModeButton: some View {
        Button {
            withAnimation(reduceMotion ? nil: .easeInOut(duration: 0.2)) {
                viewModel.selectionModeEnabled.toggle()
            }
        } label: {
            Image(systemName: "mappin.circle")
                .symbolVariant(viewModel.selectionModeEnabled ? .fill : .none)
            //                .padding(10)
                .foregroundStyle(.red)
                .frame(width: 60, height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.selectionModeEnabled ? Color.red.opacity(0.15) : Color.clear)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select map location")
        .accessibilityValue(
            viewModel.selectionModeEnabled ? "On" : "Off"
        )
        .sensoryFeedback(
            .selection,
            trigger: viewModel.selectionModeEnabled
        )
    }
    
    var currentLocationButton: some View {
        Button {
            locationManager.requestPermissionAccess(onAuthorize: {
                withAnimation(.easeInOut(duration: 0.4)) {
                    viewModel.cameraPosition = .userLocation(fallback: .automatic)
                }
            }, onUnauthorized: { alertItem in
                viewModel.alertItem = alertItem
            })
        } label: {
            Image(systemName: "location")
            //                .padding(10)
            //                .background(.thinMaterial)
            //                .clipShape(Circle())
        }
    }
    
    var operationsButtonsSection: some View {
        HStack(spacing: 0) {
            Button {
                viewModel.presentFilterSheet = true
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                //                Text("Filter").font(.system(size: 20))
            }
            //            .contentShape(Rectangle())
            //            .frame(width: 150)
            
            //            Rectangle()
            //                .fill(.black)
            //                .frame(width: 0.5)
            Divider()
                .frame(height: 24)
            
            Button {
                viewModel.presentResultsSheet = true
            } label: {
                Label("Results", systemImage: "list.bullet")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            //            .contentShape(Rectangle())
            //            .frame(width: 150)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .background(.regularMaterial)
        //        .clipShape(Capsule())
        .padding(5)
        .frame(maxWidth: 340)
        .overlay(
            Capsule().strokeBorder(.black.opacity(0.4), lineWidth: 1.5)
        )
        //        .fixedSize(horizontal: false, vertical: true)
    }
}

struct RestaurantPin: View {
    var color: Color = .purple
    var icon: String = "star.fill"
    
    var body: some View {
        VStack(spacing: -1) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 20, height: 20)
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Image(systemName: "triangle.fill")
                .resizable()
                .frame(width: 8, height: 6)
                .rotationEffect(.degrees(180))
                .foregroundStyle(color)
            
            Ellipse()
                .fill(.black.opacity(0.2))
                .frame(width: 14, height: 4)
                .offset(y: 1)
        }
    }
}

struct TargetPin: View {
    var body: some View {
        ZStack {
            // Outer White Ring / Shadow Base
            Circle()
                .fill(.white)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
            
            // Inner Red Center Dot
            Circle()
                .fill(Color.red)
                .frame(width: 15, height: 15)
        }
    }
}

//struct popupNote: View {
//    var present: Bool
//    var message: String
//
//    var body: some View {
//        Text(message)
//            .padding(10)
//            .background(RoundedRectangle(cornerRadius: 5).fill(.black.opacity(0.6)))
//            .foregroundStyle(.white)
//    }
//}

#Preview {
    MapView()
}
