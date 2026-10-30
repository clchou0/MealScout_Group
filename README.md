# MealScout
Find meals to fit all your preferences

## About:
An iOS native app that helps you find food reviews around you. Filter things based by anything that matters: price, cuisine, area, portion, and everything that users ordered.

## Features:
- Restaurants within 1km distance from your desired location: Import from maps, pin on the screen, or use your current location when location is activated
- Enable pin mode to select your own location to find restaurants around
- Filter reviews by prices, portion size, cuisine, anything you care about in a meal
- Share from Apple Maps to find any spot, or restaurant you want to review
- Use the restaurant in Apple Maps

## Getting Started
- Requires Xcode 16+
- Clone the repo and open the `.xcodeproj` in Xcode
- Swift Package Manager fetches Firebase automatically on first open
- `GoogleService-Info.plist` is already included, so no Firebase setup is needed
- Select the MealScout scheme and run (⌘R)

## Dependencies
- [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk) (FirebaseAuth, FirebaseFirestore) via Swift Package Manager
- Apple frameworks: SwiftUI, MapKit, Core Location

## Things to know
- Share extension: In apple maps, open any location -> press share to MealScout -> MealScout asks you how to use the location
- Travel times need a network connection; the 1km filter works on-device
