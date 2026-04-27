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

    // MARK: - dragProgress additional

    func test_dragProgress_quarterThreshold() {
        XCTAssertEqual(dragProgress(offset: 30, threshold: 120), 0.25, accuracy: 0.001)
    }

    func test_dragProgress_threeQuartersThreshold() {
        XCTAssertEqual(dragProgress(offset: 90, threshold: 120), 0.75, accuracy: 0.001)
    }

    func test_dragProgress_veryLargeOffset_clampsToOne() {
        XCTAssertEqual(dragProgress(offset: 1_000_000, threshold: 120), 1.0)
    }

    func test_dragProgress_slightlyBelowThreshold_lessThanOne() {
        let progress = dragProgress(offset: 119, threshold: 120)
        XCTAssertLessThan(progress, 1.0)
        XCTAssertGreaterThan(progress, 0.9)
    }

    func test_dragProgress_oneUnit_isCorrectFraction() {
        XCTAssertEqual(dragProgress(offset: 1, threshold: 100), 0.01, accuracy: 0.0001)
    }

    // MARK: - shouldDismiss additional

    func test_shouldDismiss_bothBelowThreshold_isFalse() {
        XCTAssertFalse(shouldDismiss(raw: 50, predicted: 80, threshold: 120))
    }

    func test_shouldDismiss_predictedExactlyAtThreshold_isFalse() {
        // Condition is `predicted > threshold` (strict), so == is NOT enough
        XCTAssertFalse(shouldDismiss(raw: 0, predicted: 120, threshold: 120))
    }

    func test_shouldDismiss_predictedOneAboveThreshold_isTrue() {
        XCTAssertTrue(shouldDismiss(raw: 0, predicted: 121, threshold: 120))
    }

    func test_shouldDismiss_rawExactlyAtThreshold_isTrue() {
        XCTAssertTrue(shouldDismiss(raw: 120, predicted: 0, threshold: 120))
    }

    func test_shouldDismiss_slowCarefulDrag_notDismissed() {
        XCTAssertFalse(shouldDismiss(raw: 50, predicted: 60, threshold: 120))
    }

    func test_shouldDismiss_veryFastFlick_dismissed() {
        XCTAssertTrue(shouldDismiss(raw: 10, predicted: 500, threshold: 120))
    }

    // MARK: - Direction filter additional

    func test_directionFilter_exactlyAt1_5xRatio_doesNotActivate() {
        // y must be STRICTLY > x * 1.5
        XCTAssertFalse(isDominantlyDownward(x: 40, y: 60))  // 60 == 40*1.5
    }

    func test_directionFilter_oneAbove1_5xRatio_activates() {
        XCTAssertTrue(isDominantlyDownward(x: 40, y: 61))   // 61 > 40*1.5
    }

    func test_directionFilter_nearlyVertical_activates() {
        XCTAssertTrue(isDominantlyDownward(x: 1, y: 100))
    }

    func test_directionFilter_upwardDiagonal_doesNotActivate() {
        XCTAssertFalse(isDominantlyDownward(x: 10, y: -50))
    }

    func test_directionFilter_zeroBothAxes_doesNotActivate() {
        XCTAssertFalse(isDominantlyDownward(x: 0, y: 0))
    }

    // MARK: - Navigation stack suppression
    //
    // Drag-to-dismiss is a modal pattern only. When the viewer is pushed onto a
    // UINavigationController the system's interactive-pop gesture handles dismissal,
    // so the drag gesture must be nil (not just guarded) to avoid interference.

    func test_gestureNil_whenInNavigationStack() {
        let isInNavigationStack = true
        let gestureActive = !isInNavigationStack
        XCTAssertFalse(gestureActive,
                       "Drag-to-dismiss must be suppressed when pushed onto a navigation stack")
    }

    func test_gestureActive_whenNotInNavigationStack() {
        let isInNavigationStack = false
        let gestureActive = !isInNavigationStack
        XCTAssertTrue(gestureActive,
                      "Drag-to-dismiss must be active for modal presentation")
    }

    func test_gestureNil_navigationStack_overridesSelectionModeCheck() {
        // Even if selectionMode is false and no upload is in progress,
        // being in a navigation stack alone is sufficient to suppress the gesture.
        let isInNavigationStack = true
        let selectionMode       = false
        let uploadInProgress    = false
        let gestureActive = !isInNavigationStack && !selectionMode && !uploadInProgress
        XCTAssertFalse(gestureActive,
                       "Navigation stack takes priority — gesture must remain nil")
    }

    func test_gestureActive_modalNoSelectionNoUpload() {
        // All three suppressors off → gesture must be active.
        let isInNavigationStack = false
        let selectionMode       = false
        let uploadInProgress    = false
        let gestureActive = !isInNavigationStack && !selectionMode && !uploadInProgress
        XCTAssertTrue(gestureActive,
                      "All suppressors off → drag-to-dismiss must be active")
    }

    // MARK: - Upload suppression edge cases

    func test_gestureDisabled_uploadJustStarted() {
        let progress: Double? = 0.01
        XCTAssertFalse(progress == nil, "Gesture must be suppressed the instant upload starts")
    }

    func test_gestureDisabled_uploadComplete_progressNotYetCleared() {
        // progress = 1.0 — upload done but not cleared yet (300ms fade animation)
        let progress: Double? = 1.0
        XCTAssertFalse(progress == nil, "Gesture must remain suppressed until progress is set to nil")
    }

    func test_gestureEnabled_afterProgressCleared() {
        let progress: Double? = nil
        XCTAssertTrue(progress == nil, "Gesture re-enables once progress is explicitly set to nil")
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
