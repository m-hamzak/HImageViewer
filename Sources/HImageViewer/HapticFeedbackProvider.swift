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
final class HapticFeedbackProvider: HapticFeedbackProviding {
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
