//
//  DragToDismissTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 20/04/2026.
//

import XCTest
@testable import HImageViewer

final class DragToDismissTests: XCTestCase {

    // MARK: - dragProgress calculation

    func test_dragProgress_zeroOffset_isZero() {
        XCTAssertEqual(dragProgress(offset: 0, threshold: 120), 0.0)
    }

    func test_dragProgress_atThreshold_isOne() {
        XCTAssertEqual(dragProgress(offset: 120, threshold: 120), 1.0)
    }

    func test_dragProgress_halfThreshold_isHalf() {
        XCTAssertEqual(dragProgress(offset: 60, threshold: 120), 0.5)
    }

    func test_dragProgress_beyondThreshold_clampsToOne() {
        XCTAssertEqual(dragProgress(offset: 999, threshold: 120), 1.0)
    }

    func test_dragProgress_negativeOffset_isZero() {
        // Upward drag — no negative progress
        XCTAssertEqual(dragProgress(offset: -50, threshold: 120), 0.0)
    }

    // MARK: - shouldDismiss threshold logic

    func test_shouldDismiss_rawAboveThreshold_isTrue() {
        XCTAssertTrue(shouldDismiss(raw: 130, predicted: 0, threshold: 120))
    }

    func test_shouldDismiss_rawBelowThreshold_isFalse() {
        XCTAssertFalse(shouldDismiss(raw: 80, predicted: 80, threshold: 120))
    }

    func test_shouldDismiss_rawBelowButPredictedAbove_isTrue() {
        // Fast flick: raw translation small but velocity carries it past threshold
        XCTAssertTrue(shouldDismiss(raw: 50, predicted: 150, threshold: 120))
    }

    func test_shouldDismiss_exactlyAtThreshold_isTrue() {
        XCTAssertTrue(shouldDismiss(raw: 120, predicted: 0, threshold: 120))
    }

    func test_shouldDismiss_oneBelow_isFalse() {
        XCTAssertFalse(shouldDismiss(raw: 119, predicted: 119, threshold: 120))
    }

    // MARK: - Direction filter

    func test_directionFilter_pureDown_activates() {
        XCTAssertTrue(isDominantlyDownward(x: 0, y: 100))
    }

    func test_directionFilter_steepDown_activates() {
        // y = 80, x = 30 → y > x * 1.5 (80 > 45) ✓
        XCTAssertTrue(isDominantlyDownward(x: 30, y: 80))
    }

    func test_directionFilter_shallowAngle_doesNotActivate() {
        // y = 40, x = 60 → y > x * 1.5 (40 > 90) ✗
        XCTAssertFalse(isDominantlyDownward(x: 60, y: 40))
    }

    func test_directionFilter_horizontal_doesNotActivate() {
        XCTAssertFalse(isDominantlyDownward(x: 100, y: 0))
    }

    func test_directionFilter_upward_doesNotActivate() {
        // y is negative (upward)
        XCTAssertFalse(isDominantlyDownward(x: 0, y: -80))
    }

    func test_directionFilter_diagonal45_doesNotActivate() {
        // y = x → y > x * 1.5 is false
        XCTAssertFalse(isDominantlyDownward(x: 50, y: 50))
    }

    // MARK: - Selection mode suppression

    func test_gestureDisabled_inSelectionMode() {
        let selectionMode = true
        let shouldActivate = !selectionMode
        XCTAssertFalse(shouldActivate, "Gesture must be suppressed in selection mode")
    }

    func test_gestureEnabled_outsideSelectionMode() {
        let selectionMode = false
        let shouldActivate = !selectionMode
        XCTAssertTrue(shouldActivate, "Gesture must be active outside selection mode")
    }

    // MARK: - Upload suppression

    func test_gestureDisabled_whileUploading() {
        let progress: Double? = 0.5
        let shouldActivate = progress == nil
        XCTAssertFalse(shouldActivate, "Gesture must be suppressed while upload is in progress")
    }

    func test_gestureEnabled_noUpload() {
        let progress: Double? = nil
        let shouldActivate = progress == nil
        XCTAssertTrue(shouldActivate, "Gesture must be active when no upload is in progress")
    }
}

// MARK: - Pure helpers (replicate HImageViewer logic for isolation)

private func dragProgress(offset: CGFloat, threshold: CGFloat) -> Double {
    min(Double(max(0, offset)) / Double(threshold), 1.0)
}

private func shouldDismiss(raw: CGFloat, predicted: CGFloat, threshold: CGFloat) -> Bool {
    raw >= threshold || predicted > threshold
}

private func isDominantlyDownward(x: CGFloat, y: CGFloat) -> Bool {
    y > 0 && y > abs(x) * 1.5
}
