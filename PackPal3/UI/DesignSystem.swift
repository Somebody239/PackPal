//
//  DesignSystem.swift
//  PackPal3
//
//  Created by AI Assistant on 2025-10-02.
//  Centralized design system with colors, spacing, typography, and other design tokens
//

import UIKit

/// Centralized design system providing consistent colors, spacing, typography, and other design tokens
/// Used throughout the app to maintain visual consistency
enum DesignSystem {
    // MARK: - Colors
    
    enum Color {
        /// Dark background color for the main app background
        static let background = UIColor(white: 0.08, alpha: 1.0)
        /// Semi-transparent surface color for cards and overlays
        static let surface = UIColor.white.withAlphaComponent(0.08)
        /// Border color for surface elements
        static let surfaceBorder = UIColor.white.withAlphaComponent(0.15)
        /// Primary brand color (orange)
        static let primary = UIColor.systemOrange
        /// Text color on primary background
        static let onPrimary = UIColor.white
        /// Primary text color
        static let textPrimary = UIColor.white
        /// Secondary text color
        static let textSecondary = UIColor(white: 0.7, alpha: 1.0)
        /// Tertiary text color
        static let textTertiary = UIColor(white: 0.6, alpha: 1.0)
    }

    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Border Radius
    
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 28
    }

    // MARK: - Typography
    
    enum Font {
        static func title(_ size: CGFloat = 28) -> UIFont { .systemFont(ofSize: size, weight: .bold) }
        static func subtitle(_ size: CGFloat = 17) -> UIFont { .systemFont(ofSize: size, weight: .semibold) }
        static func body(_ size: CGFloat = 16) -> UIFont { .systemFont(ofSize: size, weight: .regular) }
        static func caption(_ size: CGFloat = 12) -> UIFont { .systemFont(ofSize: size, weight: .medium) }
    }
}

