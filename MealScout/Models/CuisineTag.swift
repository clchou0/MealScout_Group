//
//  RestaurantTag.swift
//  MealScout
//
//  Created by CLChou on 2026/9/23.
//

import Foundation

/// Country nanmes and code mapping. Cuisine tags have country(code) that display the flag

struct CountryGlossary {
    static let allowedCountryCodes: Set<String> = [
        "TH", // Thailand
        "JP", // Japan
        "CN", // China
        "MX", // Mexico
        "US", // United States
        "DE", // Germany
        "IT", // Italy
        "ES", // Spain
        "FR", // France
        "TW", // Taiwan
        "ID", // Indonesia
        "MY", // Malaysia
        "VN", // Vietnam
        "BR", // Brazil
        "IN", // India
        "KR", // Korea
        "LB", // Lebanon
        "TR", // Turkey
        "GR", // Greece
        "GB", // United Kingdom
    ]
    
    static let cuisineNameByCode: [String: String] = [
        "TH": "Thai",
        "JP": "Japanese",
        "CN": "Chinese",
        "MX": "Mexican",
        "US": "American",
        "DE": "German",
        "IT": "Italian",
        "ES": "Spanish",
        "FR": "French",
        "TW": "Taiwanese",
        "ID": "Indonesian",
        "MY": "Malaysian",
        "VN": "Vietnamese",
        "BR": "Brazilian",
        "IN": "Indian",
        "KR": "Korean",
        "LB": "Lebanese",
        "TR": "Turkish",
        "GR": "Greek",
        "GB": "British"
    ]
}

enum CuisineTag: Hashable, Codable, Equatable {
    // Non-nationality
    case cafe
    case fastFood
    case dessert
    case drinksFocused
    case bakery
    case buffet
    case seafood
    case bbq
    case fingerFood
    
    // Nationality
    case country(code: String)          // Common cuisines, will have their own icons
    case international(name: String)     // U can type the cuisine in yourself, would have default icon
    
    var displayIcon: String {
        
        return switch (self) {
            case .country(let code): flag(from: code)
            case .international(_): "🌍"
            case .cafe: "☕️"
            case .fastFood: "🍔"
            case .dessert: "🍰"
            case .drinksFocused: "🍸"
            case .bakery: "🥐"
            case .buffet: "🍽️"
            case .seafood: "🦐"
            case .bbq: "🍖"
            case .fingerFood: "🍢"
        }
    }
    
    func flag(from countryCode: String) -> String {
        let base: UInt32 = 127397
        var flagString = ""
        
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicodeScalar = UnicodeScalar(base + scalar.value) {
                flagString.unicodeScalars.append(unicodeScalar)
            }
        }
        
        return flagString
    }
    
    var labelName: String {
        switch self {
        case .cafe: "Cafe"
        case .fastFood: "Fast Food"
        case .dessert: "Dessert"
        case .drinksFocused: "Drinks Focused"
        case .bakery: "Bakery"
        case .buffet: "Buffet"
        case .seafood: "Seafood"
        case .bbq: "Barbeque"
        case .fingerFood: "Finger Food"
        case .country(let code):
            CountryGlossary.cuisineNameByCode[code] ?? code
        case .international(let name):
            name
        }
    }
}

extension CuisineTag: CaseIterable {
    public static var allCases: [CuisineTag] {
        [
            .cafe,
            .fastFood,
            .dessert,
            .drinksFocused,
            .bakery,
            .buffet,
            .seafood,
            .bbq,
            .fingerFood,
            .country(code: "TH"),
            .country(code: "JP"),
            .country(code: "CN"),
            .country(code: "MX"),
            .country(code: "US"),
            .country(code: "DE"),
            .country(code: "IT"),
            .country(code: "ES"),
            .country(code: "FR"),
            .country(code: "TW"),
            .country(code: "ID"),
            .country(code: "MY"),
            .country(code: "VN"),
            .country(code: "BR"),
            .country(code: "IN"),
            .country(code: "KR"),
            .country(code: "LB"),
            .country(code: "TR"),
            .country(code: "GR"),
            .country(code: "GB")
        ].sorted{ $0.labelName < $1.labelName }
    }
}
