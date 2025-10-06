//
//  SettingsManager.swift
//  PackPal3
//
//  Created by AI Assistant on 2025-10-02.
//  Manages user preferences and app settings using UserDefaults
//

import Foundation

// MARK: - SettingsManager

/// Manages user preferences and app settings
/// All settings are persisted using UserDefaults with proper key management
enum SettingsManager {

    // MARK: - Private Keys
    
    /// UserDefaults keys for all settings
    private enum Keys {
        static let showCountryFlags = "settings.showCountryFlags"
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let temperatureUnit = "settings.temperatureUnit" // "c" or "f"
        static let distanceUnit = "settings.distanceUnit" // "km" or "mi"
    }

    // MARK: - Public Settings Properties
    
    /// Whether to show country flags in the UI
    static var showCountryFlags: Bool {
        get { UserDefaults.standard.object(forKey: Keys.showCountryFlags) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.showCountryFlags) }
    }

    /// Whether haptic feedback is enabled
    static var hapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.hapticsEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hapticsEnabled) }
    }

    /// Whether notifications are enabled
    static var notificationsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.notificationsEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    /// Temperature unit preference ("c" for Celsius, "f" for Fahrenheit)
    static var temperatureUnit: String {
        get { UserDefaults.standard.string(forKey: Keys.temperatureUnit) ?? "c" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.temperatureUnit) }
    }

    /// Distance unit preference ("km" for kilometers, "mi" for miles)
    static var distanceUnit: String {
        get { UserDefaults.standard.string(forKey: Keys.distanceUnit) ?? "km" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.distanceUnit) }
    }
}

