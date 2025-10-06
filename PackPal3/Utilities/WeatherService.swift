//
//  WeatherService.swift
//  PackPal3
//
//  Created by AI Assistant on 2025-10-02.
//  Weather service for fetching weather data and forecasts
//

import Foundation
import CoreLocation

// MARK: - Weather Models

/// Weather summary for a destination
struct WeatherSummary {
    let icon: String
    let description: String
    let currentTemp: Double?
    let minTemp: Double?
    let maxTemp: Double?
    
    init(icon: String, description: String, currentTemp: Double? = nil, minTemp: Double? = nil, maxTemp: Double? = nil) {
        self.icon = icon
        self.description = description
        self.currentTemp = currentTemp
        self.minTemp = minTemp
        self.maxTemp = maxTemp
    }
}

/// Geocoding API response
struct GeoResponse: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String?
}

/// Weather API response structure
struct WeatherResponse: Codable {
    let current: Current
    let daily: [Daily]
    
    struct Current: Codable {
        let temp: Double
        let weather: [Weather]
    }
    
    struct Weather: Codable {
        let description: String
        let icon: String
        let main: String
    }
    
    struct Daily: Codable {
        let dt: Int
        let temp: Temp
        let weather: [Weather]
        
        struct Temp: Codable {
            let min: Double
            let max: Double
        }
    }
}

// MARK: - WeatherService

/// Service for fetching weather data and forecasts
class WeatherService {
    
    // MARK: - Constants
    
    private static let API_KEY = "9cfef7aeb892cf5e13d3ed85eb4f6adb"
    private static let GEOCODING_URL = "https://api.openweathermap.org/geo/1.0/direct"
    private static let WEATHER_URL = "https://api.openweathermap.org/data/3.0/onecall"
    
    // Cache to avoid repeated API calls
    private static var cache: [String: (summary: WeatherSummary, timestamp: Date)] = [:]
    private static let CACHE_DURATION: TimeInterval = 3600 // 1 hour
    
    // MARK: - Public Methods
    
    /// Fetches weather summary for a destination
    /// - Parameters:
    ///   - destination: City name (e.g., "Paris", "New York")
    ///   - start: Trip start date
    ///   - end: Trip end date
    ///   - completion: Callback with weather summary
    static func fetchSummary(for destination: String, start: Date, end: Date, completion: @escaping (WeatherSummary) -> Void) {
        
        // Check cache first
        let unitKey = SettingsManager.temperatureUnit // "c" or "f"
        let cacheKey = "\(destination)_\(start.timeIntervalSince1970)_\(unitKey)"
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < CACHE_DURATION {
            print("✅ Using cached weather for \(destination)")
            DispatchQueue.main.async {
                completion(cached.summary)
            }
            return
        }
        
        // Step 1: Geocode the destination
        geocodeCity(destination) { coordinates in
            guard let coordinates = coordinates else {
                print("⚠️ Geocoding failed, using fallback weather")
                completion(fallbackWeather(for: start))
                return
            }
            
            // Step 2: Fetch weather with coordinates
            fetchWeather(lat: coordinates.latitude, lon: coordinates.longitude) { summary in
                // Cache the result
                cache[cacheKey] = (summary, Date())
                completion(summary)
            }
        }
    }

    /// Clears the internal cache (e.g., triggered from Settings)
    static func clearCache() {
        cache.removeAll()
        print("🧹 Weather cache cleared")
    }
    
    // MARK: - Private Methods
    
    /// Step 1: Convert city name to coordinates
    private static func geocodeCity(_ city: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let cityEncoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "\(GEOCODING_URL)?q=\(cityEncoded)&limit=1&appid=\(API_KEY)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid geocoding URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Geocoding error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let data = data else {
                print("❌ No geocoding data received")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let geoResults = try JSONDecoder().decode([GeoResponse].self, from: data)
                
                if let first = geoResults.first {
                    print("✅ Geocoded \(city) to (\(first.lat), \(first.lon))")
                    let coordinate = CLLocationCoordinate2D(latitude: first.lat, longitude: first.lon)
                    DispatchQueue.main.async {
                        completion(coordinate)
                    }
                } else {
                    print("⚠️ No geocoding results for \(city)")
                    DispatchQueue.main.async { completion(nil) }
                }
            } catch {
                print("❌ Geocoding parse error: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
    
    /// Step 2: Fetch weather data using coordinates
    private static func fetchWeather(lat: Double, lon: Double, completion: @escaping (WeatherSummary) -> Void) {
        let usesMetric = SettingsManager.temperatureUnit == "c"
        let unitsParam = usesMetric ? "metric" : "imperial"
        let urlString = "\(WEATHER_URL)?lat=\(lat)&lon=\(lon)&appid=\(API_KEY)&units=\(unitsParam)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid weather URL")
            DispatchQueue.main.async {
                completion(fallbackWeather(for: Date()))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Weather API error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(fallbackWeather(for: Date()))
                }
                return
            }
            
            guard let data = data else {
                print("❌ No weather data received")
                DispatchQueue.main.async {
                    completion(fallbackWeather(for: Date()))
                }
                return
            }
            
            // Debug: Print response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Weather Response: \(jsonString.prefix(200))...")
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                
                let currentTemp = weatherResponse.current.temp
                let description = weatherResponse.current.weather.first?.description.capitalized ?? "Unknown"
                let weatherMain = weatherResponse.current.weather.first?.main ?? ""
                
                // Get forecast min/max from next few days
                let minTemp = weatherResponse.daily.prefix(3).map { $0.temp.min }.min()
                let maxTemp = weatherResponse.daily.prefix(3).map { $0.temp.max }.max()
                
                // Map weather condition to SF Symbol
                let icon = mapWeatherIcon(weatherMain: weatherMain)
                
                let summary = WeatherSummary(
                    icon: icon,
                    description: description,
                    currentTemp: currentTemp,
                    minTemp: minTemp,
                    maxTemp: maxTemp
                )
                
                let unitSymbol = usesMetric ? "C" : "F"
                print("✅ Weather fetched: \(description), \(Int(currentTemp))°\(unitSymbol)")
                DispatchQueue.main.async {
                    completion(summary)
                }
            } catch {
                print("❌ Weather parse error: \(error)")
                DispatchQueue.main.async {
                    completion(fallbackWeather(for: Date()))
                }
            }
        }.resume()
    }
    
    /// Maps OpenWeather condition to SF Symbol icon
    private static func mapWeatherIcon(weatherMain: String) -> String {
        switch weatherMain.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog", "haze":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }
    
    /// Fallback weather based on month if API fails
    private static func fallbackWeather(for date: Date) -> WeatherSummary {
        let month = Calendar.current.component(.month, from: date)
        
        switch month {
        case 6...9:
            return WeatherSummary(icon: "sun.max.fill", description: "Warm (75–90°F)")
        case 3...5, 10...11:
            return WeatherSummary(icon: "cloud.sun.fill", description: "Moderate (60–70°F)")
        case 12, 1, 2:
            return WeatherSummary(icon: "cloud.snow.fill", description: "Cool (40–55°F)")
        default:
            return WeatherSummary(icon: "cloud.fill", description: "Variable")
        }
    }
}

