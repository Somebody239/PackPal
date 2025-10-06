//
//  Trip.swift
//  PackPal3
//
//  Created by Kishan Joshi on 2025-10-01.
//  Core data models for trips, packing categories, and related entities
//

import Foundation
import CoreLocation
import UIKit

// MARK: - Trip

/// Represents a trip with all necessary information for packing recommendations
struct Trip: Codable {
    let id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var occasion: TripOccasion
    var activities: [TripActivity]
    var expectedWeather: WeatherCondition
    var tripType: TripType
    var packingCategories: [PackingCategory]
    var notes: String
    var images: [TripImage]
    var documents: [TripDocument]
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        occasion: TripOccasion,
        activities: [TripActivity] = [],
        expectedWeather: WeatherCondition = .moderate,
        tripType: TripType = .leisure,
        packingCategories: [PackingCategory] = [],
        notes: String = "",
        images: [TripImage] = [],
        documents: [TripDocument] = [],
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.occasion = occasion
        self.activities = activities
        self.expectedWeather = expectedWeather
        self.tripType = tripType
        self.packingCategories = packingCategories
        self.notes = notes
        self.images = images
        self.documents = documents
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    var isDateRangeValid: Bool { endDate >= startDate }

    func validationErrors() -> [String] {
        var errors: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors.append("Trip name is required.") }
        if destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors.append("Destination is required.") }
        if !isDateRangeValid { errors.append("End date must be on or after start date.") }
        return errors
    }

    var coordinate: CLLocationCoordinate2D? {
        TripGeocoder.shared.cachedCoordinate(for: destination)
    }

    mutating func updateTimestamp() {
        updatedAt = Date()
    }
}

// MARK: - TripOccasion

/// Types of trip occasions that affect packing recommendations
enum TripOccasion: String, Codable, CaseIterable {
    case business = "Business"
    case vacation = "Vacation"
    case adventure = "Adventure"
    case family = "Family Visit"
    case romantic = "Romantic Getaway"
    case solo = "Solo Travel"
    case group = "Group Trip"
    case wedding = "Wedding"
    case conference = "Conference"
    case other = "Other"
}

// MARK: - TripActivity

/// Specific activities that help determine packing needs
enum TripActivity: String, Codable, CaseIterable {
    case beach = "Beach"
    case hiking = "Hiking"
    case skiing = "Skiing"
    case swimming = "Swimming"
    case cityTour = "City Tour"
    case museum = "Museum Visits"
    case dining = "Fine Dining"
    case shopping = "Shopping"
    case photography = "Photography"
    case business = "Business Meetings"
    case sports = "Sports Events"
    case concerts = "Concerts/Shows"
    case camping = "Camping"
    case fishing = "Fishing"
    case other = "Other"
}

// MARK: - WeatherCondition

/// Expected weather conditions for packing recommendations
enum WeatherCondition: String, Codable, CaseIterable {
    case hot = "Hot (80°F+)"
    case warm = "Warm (70-80°F)"
    case moderate = "Moderate (60-70°F)"
    case cool = "Cool (50-60°F)"
    case cold = "Cold (Below 50°F)"
    case rainy = "Rainy"
    case snowy = "Snowy"
    case variable = "Variable"
}

// MARK: - TripType

/// Trip type categories for different packing strategies
enum TripType: String, Codable, CaseIterable {
    case leisure = "Leisure"
    case business = "Business"
    case adventure = "Adventure"
    case luxury = "Luxury"
    case budget = "Budget"
    case family = "Family"
    case romantic = "Romantic"
    case solo = "Solo"
}

// MARK: - PackingCategory

/// Packing categories for organizing items
struct PackingCategory: Codable, Identifiable {
    let id: UUID
    var name: String
    var items: [PackingItem]
    var isCompleted: Bool

    init(id: UUID = UUID(), name: String, items: [PackingItem] = [], isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.items = items
        self.isCompleted = isCompleted
    }
}

// MARK: - PackingItem

/// Individual packing items
struct PackingItem: Codable, Identifiable {
    let id: UUID
    var name: String
    var isPacked: Bool
    var quantity: Int
    var notes: String

    init(id: UUID = UUID(), name: String, isPacked: Bool = false, quantity: Int = 1, notes: String = "") {
        self.id = id
        self.name = name
        self.isPacked = isPacked
        self.quantity = quantity
        self.notes = notes
    }
}

// MARK: - TripImage

/// Trip images for visual reference
struct TripImage: Codable, Identifiable {
    let id: UUID
    var imageData: Data?
    var url: String?
    var caption: String
    var dateAdded: Date

    init(id: UUID = UUID(), imageData: Data? = nil, url: String? = nil, caption: String = "", dateAdded: Date = Date()) {
        self.id = id
        self.imageData = imageData
        self.url = url
        self.caption = caption
        self.dateAdded = dateAdded
    }
}

// MARK: - TripDocument

/// Trip documents (PDFs, itineraries, etc.)
struct TripDocument: Codable, Identifiable {
    let id: UUID
    var fileName: String
    var fileData: Data?
    var fileType: String
    var dateAdded: Date

    init(id: UUID = UUID(), fileName: String, fileData: Data? = nil, fileType: String, dateAdded: Date = Date()) {
        self.id = id
        self.fileName = fileName
        self.fileData = fileData
        self.fileType = fileType
        self.dateAdded = dateAdded
    }
}

// MARK: - TripManager

/// Manages all trips in the app
class TripManager {
    static let shared = TripManager()

    private let tripsKey = "savedTrips"

    private init() {}

    /// Save a trip to persistent storage
    func saveTrip(_ trip: Trip) {
        var trips = loadTrips()
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
        } else {
            trips.append(trip)
        }
        saveTrips(trips)
    }

    /// Load all trips from persistent storage
    func loadTrips() -> [Trip] {
        guard let data = UserDefaults.standard.data(forKey: tripsKey),
              let trips = try? JSONDecoder().decode([Trip].self, from: data) else {
            return []
        }
        return trips
    }

    /// Delete a trip
    func deleteTrip(_ trip: Trip) {
        var trips = loadTrips()
        trips.removeAll(where: { $0.id == trip.id })
        saveTrips(trips)
    }

    /// Get a trip by ID
    func getTrip(id: UUID) -> Trip? {
        return loadTrips().first(where: { $0.id == id })
    }

    private func saveTrips(_ trips: [Trip]) {
        if let data = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(data, forKey: tripsKey)
        }
    }
}

// MARK: - Packing Suggestions

extension Trip {
    static func suggestedPackingCategories(occasion: TripOccasion,
                                           activities: [TripActivity],
                                           weather: WeatherCondition,
                                           durationDays: Int) -> [PackingCategory] {
        var categories: [PackingCategory] = []
        let days = max(1, durationDays)

        // Essentials (always needed)
        var essentials: [PackingItem] = [
            .init(name: "Passport / ID"),
            .init(name: "Wallet & Cards"),
            .init(name: "Phone + Charger"),
            .init(name: "Medications"),
            .init(name: "Travel Documents")
        ]
        if occasion == .business || occasion == .conference {
            essentials.append(.init(name: "Laptop + Charger"))
            essentials.append(.init(name: "Business Cards"))
        }
        categories.append(PackingCategory(name: "Essentials", items: essentials))

        // Smart clothing based on duration and occasion
        var clothing: [PackingItem] = []
        
        // Calculate outfits: generally 1 outfit per day, but can re-wear bottoms
        let totalOutfits = days
        let topsQty = totalOutfits // One top per day
        let bottomsQty = max(2, (days + 1) / 2) // Re-wear pants/skirts
        let underwearQty = days + 1 // Extra set
        let socksQty = days + 1 // Extra pair
        
        // Occasion-specific formal wear
        switch occasion {
        case .wedding:
            clothing.append(.init(name: "Wedding Attire (Dress/Suit)"))
            clothing.append(.init(name: "Dress Shoes"))
            clothing.append(.init(name: "Formal Accessories"))
            
        case .business, .conference:
            clothing.append(.init(name: "Business Suits", quantity: min(3, days)))
            clothing.append(.init(name: "Dress Shirts", quantity: topsQty))
            clothing.append(.init(name: "Dress Pants", quantity: bottomsQty))
            clothing.append(.init(name: "Ties/Scarves", quantity: 2))
            clothing.append(.init(name: "Dress Shoes"))
            clothing.append(.init(name: "Belt"))
            
        case .romantic:
            // Romantic getaway - nice but not too formal
            clothing.append(.init(name: "Evening Wear", quantity: 2))
            clothing.append(.init(name: "Smart Casual Outfits", quantity: max(1, topsQty - 2)))
            clothing.append(.init(name: "Nice Pants/Skirts", quantity: bottomsQty))
            clothing.append(.init(name: "Dress Shoes"))
            clothing.append(.init(name: "Accessories"))
            
        case .vacation, .adventure, .family, .solo, .group, .other:
            // Casual clothing for vacation/adventure
            clothing.append(.init(name: "T-Shirts/Tops", quantity: topsQty))
            clothing.append(.init(name: "Pants/Jeans", quantity: bottomsQty))
            if weather == .hot || weather == .warm {
                clothing.append(.init(name: "Shorts", quantity: max(2, days / 2)))
            }
        }
        
        // Add basics
        clothing.append(.init(name: "Underwear", quantity: underwearQty))
        clothing.append(.init(name: "Socks", quantity: socksQty))
        clothing.append(.init(name: "Sleepwear", quantity: 2))
        
        // Weather-dependent clothing
        switch weather {
        case .hot, .warm:
            clothing.append(.init(name: "Sun Hat/Cap"))
            clothing.append(.init(name: "Sunglasses"))
            if occasion == .vacation || occasion == .adventure || occasion == .family {
                clothing.append(.init(name: "Sandals"))
            }
        case .cool:
            clothing.append(.init(name: "Light Jacket"))
            clothing.append(.init(name: "Long Pants", quantity: bottomsQty))
        case .cold, .snowy:
            clothing.append(.init(name: "Winter Coat"))
            clothing.append(.init(name: "Warm Sweaters", quantity: 2))
            clothing.append(.init(name: "Thermal Underwear"))
            clothing.append(.init(name: "Gloves"))
            clothing.append(.init(name: "Winter Hat/Beanie"))
            clothing.append(.init(name: "Scarf"))
            clothing.append(.init(name: "Warm Boots"))
        case .moderate, .rainy, .variable:
            clothing.append(.init(name: "Light Jacket"))
        }
        
        categories.append(PackingCategory(name: "Clothing", items: clothing))

        // Weather gear (based on conditions)
        var weatherGear: [PackingItem] = []
        switch weather {
        case .rainy:
            weatherGear.append(.init(name: "Umbrella"))
            weatherGear.append(.init(name: "Rain Jacket/Poncho"))
            weatherGear.append(.init(name: "Waterproof Shoes"))
        case .hot, .warm:
            weatherGear.append(.init(name: "Sunscreen SPF 50+"))
            weatherGear.append(.init(name: "Aloe Vera (sunburn)"))
            weatherGear.append(.init(name: "Lip Balm SPF"))
            weatherGear.append(.init(name: "Cooling Towel"))
        case .cold, .snowy:
            weatherGear.append(.init(name: "Hand Warmers"))
            weatherGear.append(.init(name: "Insulated Water Bottle"))
        case .moderate, .cool, .variable:
            break
        }
        if !weatherGear.isEmpty {
            categories.append(PackingCategory(name: "Weather Essentials", items: weatherGear))
        }

        // Toiletries
        var toiletries: [PackingItem] = [
            .init(name: "Toothbrush & Toothpaste"),
            .init(name: "Deodorant"),
            .init(name: "Shampoo & Conditioner"),
            .init(name: "Body Wash/Soap"),
            .init(name: "Face Wash"),
            .init(name: "Moisturizer"),
            .init(name: "Hair Brush/Comb")
        ]
        if weather == .hot || weather == .warm {
            toiletries.append(.init(name: "Sunscreen"))
            toiletries.append(.init(name: "After-Sun Lotion"))
        }
        if occasion == .romantic || occasion == .wedding {
            toiletries.append(.init(name: "Makeup/Grooming Kit"))
            toiletries.append(.init(name: "Perfume/Cologne"))
            toiletries.append(.init(name: "Hair Styling Products"))
        }
        categories.append(PackingCategory(name: "Toiletries", items: toiletries))

        // Activity-specific items
        var activityItems: [PackingItem] = []
        if activities.contains(.beach) || activities.contains(.swimming) {
            activityItems += [
                .init(name: "Swimsuit"),
                .init(name: "Beach Towel"),
                .init(name: "Flip Flops"),
                .init(name: "Waterproof Phone Case"),
                .init(name: "Snorkel Gear (optional)")
            ]
        }
        if activities.contains(.hiking) {
            activityItems += [
                .init(name: "Hiking Boots"),
                .init(name: "Daypack/Backpack"),
                .init(name: "Water Bottle"),
                .init(name: "Trail Snacks"),
                .init(name: "First Aid Kit"),
                .init(name: "Hiking Poles (optional)")
            ]
        }
        if activities.contains(.skiing) {
            activityItems += [
                .init(name: "Ski Jacket & Pants"),
                .init(name: "Thermal Base Layers"),
                .init(name: "Ski Goggles"),
                .init(name: "Gloves (waterproof)"),
                .init(name: "Ski Socks"),
                .init(name: "Helmet (or rent)")
            ]
        }
        if activities.contains(.sports) {
            activityItems += [
                .init(name: "Athletic Wear"),
                .init(name: "Running Shoes"),
                .init(name: "Gym Bag"),
                .init(name: "Workout Towel")
            ]
        }
        if activities.contains(.photography) {
            activityItems += [
                .init(name: "Camera + Lenses"),
                .init(name: "Extra Batteries"),
                .init(name: "Memory Cards"),
                .init(name: "Tripod")
            ]
        }
        if !activityItems.isEmpty {
            categories.append(PackingCategory(name: "Activities", items: activityItems))
        }

        return categories
    }
}
