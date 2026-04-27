//
//  ProgressRingOverlayViewTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 27/04/2026.
//

import XCTest
@testable import HImageViewer

/// Tests for `ProgressRingOverlayView.progressAccessibilityLabel`.
///
/// The label is the only logic-bearing surface in this view:
/// all visual layout is covered by SwiftUI's own rendering engine.
final class ProgressRingOverlayViewTests: XCTestCase {

    // MARK: - No title

    func test_label_noTitle_zeroPercent() {
        let view = ProgressRingOverlayView(progress: 0.0)
        XCTAssertEqual(view.progressAccessibilityLabel, "Upload progress, 0 percent")
    }

    func test_label_noTitle_fiftyPercent() {
        let view = ProgressRingOverlayView(progress: 0.5)
        XCTAssertEqual(view.progressAccessibilityLabel, "Upload progress, 50 percent")
    }

    func test_label_noTitle_hundredPercent() {
        let view = ProgressRingOverlayView(progress: 1.0)
        XCTAssertEqual(view.progressAccessibilityLabel, "Upload progress, 100 percent")
    }

    func test_label_noTitle_truncatesDecimal() {
        // Int(0.476 * 100) truncates to 47, not rounds to 48
        let view = ProgressRingOverlayView(progress: 0.476)
        XCTAssertEqual(view.progressAccessibilityLabel, "Upload progress, 47 percent")
    }

    func test_label_noTitle_twentyFivePercent() {
        let view = ProgressRingOverlayView(progress: 0.25)
        XCTAssertEqual(view.progressAccessibilityLabel, "Upload progress, 25 percent")
    }

    // MARK: - With title

    func test_label_withTitle_zeroPercent() {
        let view = ProgressRingOverlayView(progress: 0.0, title: "Uploading")
        XCTAssertEqual(view.progressAccessibilityLabel, "Uploading, 0 percent")
    }

    func test_label_withTitle_fiftyPercent() {
        let view = ProgressRingOverlayView(progress: 0.5, title: "Uploading")
        XCTAssertEqual(view.progressAccessibilityLabel, "Uploading, 50 percent")
    }

    func test_label_withTitle_hundredPercent() {
        let view = ProgressRingOverlayView(progress: 1.0, title: "Uploading")
        XCTAssertEqual(view.progressAccessibilityLabel, "Uploading, 100 percent")
    }

    func test_label_withCustomTitle_usesProvidedTitle() {
        let view = ProgressRingOverlayView(progress: 0.3, title: "Saving")
        XCTAssertEqual(view.progressAccessibilityLabel, "Saving, 30 percent")
    }

    // MARK: - Title presence determines format

    func test_label_nilTitle_usesDefaultPrefix() {
        let view = ProgressRingOverlayView(progress: 0.6)
        XCTAssertTrue(
            view.progressAccessibilityLabel.hasPrefix("Upload progress,"),
            "Nil title must use the default 'Upload progress,' prefix"
        )
    }

    func test_label_nonNilTitle_doesNotContainDefaultPrefix() {
        let view = ProgressRingOverlayView(progress: 0.6, title: "Syncing")
        XCTAssertFalse(
            view.progressAccessibilityLabel.contains("Upload progress"),
            "A provided title must replace the default prefix entirely"
        )
    }

    // MARK: - Label always contains "percent"

    func test_label_alwaysContainsPercentSuffix() {
        for progress in [0.0, 0.33, 0.66, 1.0] {
            let view = ProgressRingOverlayView(progress: progress)
            XCTAssertTrue(
                view.progressAccessibilityLabel.hasSuffix("percent"),
                "Label must end with 'percent' for progress \(progress)"
            )
        }
    }
}
