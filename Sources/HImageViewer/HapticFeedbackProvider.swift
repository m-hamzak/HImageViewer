//
//  HapticFeedbackProvider.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 20/04/2026.
//

import UIKit

// MARK: - Protocol

/// Abstracts UIKit haptic generation so the ViewModel stays testable.
///
/// Inject a `MockHapticFeedbackProvider` in tests to record and assert
/// haptic calls without touching real hardware.
protocol HapticFeedbackProviding {
    /// Fires an impact feedback event with the given style.
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
}

// MARK: - Real implementation

/// Default implementation that drives `UIImpactFeedbackGenerator`.
///
/// Generators are created once per style and reused across calls, avoiding
/// repeated allocation and allowing the Taptic Engine to stay primed.
final class HapticFeedbackProvider: HapticFeedbackProviding {

    private let light  = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy  = UIImpactFeedbackGenerator(style: .heavy)

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:              light.impactOccurred()
        case .medium:             medium.impactOccurred()
        case .heavy:              heavy.impactOccurred()
        @unknown default:         UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
}
