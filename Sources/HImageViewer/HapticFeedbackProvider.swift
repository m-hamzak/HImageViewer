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
    /// Fires a selection-change feedback event (used for page navigation).
    func selection()
}

// MARK: - Real implementation

/// Default implementation that drives `UIImpactFeedbackGenerator` and
/// `UISelectionFeedbackGenerator`.
///
/// All five impact styles (`.light`, `.medium`, `.heavy`, `.soft`, `.rigid`) are
/// pre-allocated so the Taptic Engine stays primed and no allocation occurs on the
/// haptic hot path.
final class HapticFeedbackProvider: HapticFeedbackProviding {

    private let light            = UIImpactFeedbackGenerator(style: .light)
    private let medium           = UIImpactFeedbackGenerator(style: .medium)
    private let heavy            = UIImpactFeedbackGenerator(style: .heavy)
    private let soft             = UIImpactFeedbackGenerator(style: .soft)
    private let rigid            = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionEngine  = UISelectionFeedbackGenerator()

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:              light.impactOccurred()
        case .medium:             medium.impactOccurred()
        case .heavy:              heavy.impactOccurred()
        case .soft:               soft.impactOccurred()
        case .rigid:              rigid.impactOccurred()
        @unknown default:         UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }

    func selection() {
        selectionEngine.selectionChanged()
    }
}
