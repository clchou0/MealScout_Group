//
//  RestaurantSheet.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

import SwiftUI
import MapKit

struct RestaurantSheet: View {
    @State var viewModel: RestaurantSheetViewModel
    @State private var navigationPath = NavigationPath()
    
    init(mapItem: MKMapItem) {
        self.viewModel = RestaurantSheetViewModel(mapItem: mapItem)
    }
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                headerSection
                    .background(Color(.systemBackground))
                tagsBar
                
                Divider()

                // 📜 2. SCROLLABLE REVIEWS LIST (Only this scrolls)
                List {
                    Section {
                        if viewModel.reviews.isEmpty {
                            emptyPlaceholder
                        } else {
                            reviewsSection
                        }
                    } header: {
                        Text("\(viewModel.reviews.count) reviews made...")
                            .textCase(nil)
                    }
                }
                // .listStyle(.grouped)
            }
            .navigationDestination(for: MKMapItem.self) { item in
                if let name = item.name, let identifier = item.identifier {
                    LogReviewView(
                        restaurantIdentifier: identifier,
                        restaurantName: name
                    )
                }
            }
            .onAppear {
                viewModel.loadReviews()
                viewModel.loadTags()
            }
        }
    }
    
    var headerSection: some View {
        HStack {
            Text(viewModel.mapItem.name ?? "unknown")
                .font(serifFont)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity)
            VStack {
                reviewButton
                openInMapsButton
            }
        }
        .padding()
    }
    
    var reviewButton: some View {
        Button {
            navigationPath.append(viewModel.mapItem)
        } label: {
            HStack {
                Image(systemName: "pencil")
                Text("Review")
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 10))
        .disabled(viewModel.mapItem.name == nil || viewModel.mapItem.identifier == nil)
        .frame(maxWidth: 135)
    }
    
    var openInMapsButton: some View {
        Button {
            viewModel.mapItem.openInMaps()
        } label: {
            HStack {
                Image(systemName: "map.fill")
                Text("In Maps")
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 10))
        .disabled(viewModel.mapItem.name == nil || viewModel.mapItem.identifier == nil)
        .frame(maxWidth: 135)
    }
    
    var headerArea: some View {
        HStack {
            Spacer()
            Text(viewModel.mapItem.name ?? "unknown")
                .font(serifFont)
                .foregroundStyle(.gray)
            Spacer()
            
            Button {
                navigationPath.append(viewModel.mapItem)
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Review")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 10))
            .disabled(viewModel.mapItem.name == nil || viewModel.mapItem.identifier == nil)
            .padding()
        }
    }
    
    var tagsBar: some View {
        ScrollView (.horizontal) {
            HStack {
                ForEach (viewModel.cuisineTags, id: \.self) { tag in
                    HStack(spacing: 8) {
                        // Tag Text
                        Text("\(tag.displayIcon) \(tag.labelName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }.padding()
    }
    
    var emptyPlaceholder: some View {
        ContentUnavailableView {
            Label("No Reviews Yet", systemImage: "fork.knife")
        } description: {
            Text("Be the first to review this spot and share your thoughts!!")
        }
    }
    
    var reviewsSection: some View {
        ForEach(viewModel.reviews) { review in
            NavigationLink {
                ReviewFullView(review: review)
            } label: {
                ReviewCard(review: review)
            }
        }
    }
}

#Preview {
    // 1. Create a coordinate
    let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    
    // 2. Create a placemark with standard address fields
    let placemark = MKPlacemark(
        coordinate: coordinate,
        addressDictionary: [
            "Name": "Sample Restaurant",
            "Street": "123 Main St",
            "City": "San Francisco",
            "State": "CA",
            "ZIP": "94105"
        ]
    )
    
    // 3. Initialize MKMapItem with the placemark
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.name = "Sample Restaurant"
    mapItem.phoneNumber = "+1 (555) 123-4567"
    mapItem.url = URL(string: "https://example.com")
    
    // 4. Return your view
    return RestaurantSheet(mapItem: mapItem)
}
