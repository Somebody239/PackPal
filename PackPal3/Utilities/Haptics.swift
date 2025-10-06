//
//  Haptics.swift
//  PackPal3
//
//  Created by AI Assistant on 2025-10-02.
//  Haptic feedback utilities for enhanced user experience
//

import UIKit

// MARK: - Haptics

/// Haptic feedback utilities for enhanced user experience
enum Haptics {
    // MARK: - Haptic Generators
    
    static let impactLight = UIImpactFeedbackGenerator(style: .light)
    static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    static let selection = UISelectionFeedbackGenerator()
    static let success = UINotificationFeedbackGenerator()

    // MARK: - Public Methods
    
    static func light() { guard SettingsManager.hapticsEnabled else { return }; impactLight.impactOccurred() }
    static func medium() { guard SettingsManager.hapticsEnabled else { return }; impactMedium.impactOccurred() }
    static func heavy() { guard SettingsManager.hapticsEnabled else { return }; impactHeavy.impactOccurred() }
    static func tap() { guard SettingsManager.hapticsEnabled else { return }; selection.selectionChanged() }
    static func confirm() { guard SettingsManager.hapticsEnabled else { return }; success.notificationOccurred(.success) }
    static func warn() { guard SettingsManager.hapticsEnabled else { return }; success.notificationOccurred(.warning) }
    static func error() { guard SettingsManager.hapticsEnabled else { return }; success.notificationOccurred(.error) }
}

