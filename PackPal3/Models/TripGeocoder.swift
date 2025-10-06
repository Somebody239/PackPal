import Foundation
import CoreLocation

// MARK: - TripGeocoder

/// Handles geocoding of trip destinations with caching
final class TripGeocoder {
    // MARK: - Singleton
    
    static let shared = TripGeocoder()
    
    // MARK: - Private Properties
    
    private var cache: [String: CLLocationCoordinate2D] = [:]
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Returns cached coordinate for destination if available
    func cachedCoordinate(for destination: String) -> CLLocationCoordinate2D? {
        cache[destination]
    }

    /// Geocodes destination if not cached, otherwise returns cached result
    func geocodeIfNeeded(destination: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        if let coord = cache[destination] {
            completion(coord)
            return
        }

        #if compiler(>=6.0)
        #warning("CLGeocoder is deprecated in iOS 26+, consider using MKGeocodingRequest when minimum deployment target is iOS 26")
        #endif
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(destination) { [weak self] placemarks, _ in
            guard let self = self else { return }
            if let loc = placemarks?.first?.location?.coordinate {
                self.cache[destination] = loc
                completion(loc)
            } else {
                completion(nil)
            }
        }
    }
}


