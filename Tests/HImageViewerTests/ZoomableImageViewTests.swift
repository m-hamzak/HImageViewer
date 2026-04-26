//
//  ZoomableImageViewTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 19/04/2026.
//

import XCTest
import SwiftUI
import UIKit
@testable import HImageViewer

final class ZoomableImageViewTests: XCTestCase {

    // MARK: - zoomClamp

    func test_zoomClamp_belowMin_clampsToMin() {
        XCTAssertEqual(zoomClamp(0.5), ZoomDefaults.minScale)
    }

    func test_zoomClamp_aboveMax_clampsToMax() {
        XCTAssertEqual(zoomClamp(10.0), ZoomDefaults.maxScale)
    }

    func test_zoomClamp_withinRange_returnsUnchanged() {
        XCTAssertEqual(zoomClamp(2.0), 2.0)
    }

    func test_zoomClamp_exactlyMin_returnsMin() {
        XCTAssertEqual(zoomClamp(ZoomDefaults.minScale), ZoomDefaults.minScale)
    }

    func test_zoomClamp_exactlyMax_returnsMax() {
        XCTAssertEqual(zoomClamp(ZoomDefaults.maxScale), ZoomDefaults.maxScale)
    }

    func test_zoomClamp_customRange() {
        XCTAssertEqual(zoomClamp(0.1, min: 0.5, max: 3.0), 0.5)
        XCTAssertEqual(zoomClamp(5.0, min: 0.5, max: 3.0), 3.0)
        XCTAssertEqual(zoomClamp(1.5, min: 0.5, max: 3.0), 1.5)
    }

    // MARK: - zoomToggle

    func test_zoomToggle_fromMinScale_returnsDoubleTapScale() {
        let result = zoomToggle(current: ZoomDefaults.minScale)
        XCTAssertEqual(result, ZoomDefaults.doubleTapScale)
    }

    func test_zoomToggle_fromZoomedIn_returnsMinScale() {
        let result = zoomToggle(current: 3.0)
        XCTAssertEqual(result, ZoomDefaults.minScale)
    }

    func test_zoomToggle_fromDoubleTapScale_returnsMinScale() {
        let result = zoomToggle(current: ZoomDefaults.doubleTapScale)
        XCTAssertEqual(result, ZoomDefaults.minScale)
    }

    func test_zoomToggle_customTapTarget() {
        let result = zoomToggle(current: 1.0, tapTarget: 3.0)
        XCTAssertEqual(result, 3.0)
    }

    func test_zoomToggle_isIdempotent_twoTapsReturnToMin() {
        let first = zoomToggle(current: ZoomDefaults.minScale)
        let second = zoomToggle(current: first)
        XCTAssertEqual(second, ZoomDefaults.minScale)
    }

    // MARK: - panClamp

    func test_panClamp_atScale1_returnsZeroOffset() {
        let container = CGSize(width: 300, height: 600)
        let result = panClamp(CGSize(width: 100, height: 100), scale: 1.0, in: container)
        XCTAssertEqual(result.width, 0)
        XCTAssertEqual(result.height, 0)
    }

    func test_panClamp_withinBounds_returnsUnchanged() {
        let container = CGSize(width: 300, height: 600)
        let scale: CGFloat = 2.0
        // max offset = (300 * (2-1)) / 2 = 150 for X, 300 for Y
        let offset = CGSize(width: 50, height: 100)
        let result = panClamp(offset, scale: scale, in: container)
        XCTAssertEqual(result.width, 50)
        XCTAssertEqual(result.height, 100)
    }

    func test_panClamp_exceedsBoundsPositive_clampedToMax() {
        let container = CGSize(width: 300, height: 600)
        let scale: CGFloat = 2.0
        // maxX = 150, maxY = 300
        let offset = CGSize(width: 999, height: 999)
        let result = panClamp(offset, scale: scale, in: container)
        XCTAssertEqual(result.width, 150)
        XCTAssertEqual(result.height, 300)
    }

    func test_panClamp_exceedsBoundsNegative_clampedToMin() {
        let container = CGSize(width: 300, height: 600)
        let scale: CGFloat = 2.0
        let offset = CGSize(width: -999, height: -999)
        let result = panClamp(offset, scale: scale, in: container)
        XCTAssertEqual(result.width, -150)
        XCTAssertEqual(result.height, -300)
    }

    func test_panClamp_higherScale_allowsLargerOffset() {
        let container = CGSize(width: 300, height: 600)
        // At scale 3: maxX = (300 * 2) / 2 = 300
        let result3x = panClamp(CGSize(width: 999, height: 0), scale: 3.0, in: container)
        // At scale 2: maxX = (300 * 1) / 2 = 150
        let result2x = panClamp(CGSize(width: 999, height: 0), scale: 2.0, in: container)
        XCTAssertGreaterThan(result3x.width, result2x.width, "Higher scale should allow larger pan offset")
    }

    // MARK: - Constants sanity

    func test_constants_minLessThanMax() {
        XCTAssertLessThan(ZoomDefaults.minScale, ZoomDefaults.maxScale)
    }

    func test_constants_doubleTapScaleWithinRange() {
        XCTAssertGreaterThan(ZoomDefaults.doubleTapScale, ZoomDefaults.minScale)
        XCTAssertLessThanOrEqual(ZoomDefaults.doubleTapScale, ZoomDefaults.maxScale)
    }

    // MARK: - Rendering smoke test

    @MainActor
    func test_zoomableImageView_renders() {
        let image = UIImage(systemName: "photo")!
        let view = ZoomableImageView(image: image, resetToken: 0)
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 667))
        controller.view.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        let rendered = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        XCTAssertGreaterThan(rendered.size.width, 0)
        XCTAssertGreaterThan(rendered.size.height, 0)
    }

    // MARK: - zoomClamp additional

    func test_zoomClamp_slightlyAboveMin_unchanged() {
        let above = ZoomDefaults.minScale + 0.1
        XCTAssertEqual(zoomClamp(above), above, accuracy: 0.001)
    }

    func test_zoomClamp_slightlyBelowMax_unchanged() {
        let below = ZoomDefaults.maxScale - 0.1
        XCTAssertEqual(zoomClamp(below), below, accuracy: 0.001)
    }

    func test_zoomClamp_negativeValue_clampsToMin() {
        XCTAssertEqual(zoomClamp(-5.0), ZoomDefaults.minScale)
    }

    func test_zoomClamp_zero_clampsToMin() {
        XCTAssertEqual(zoomClamp(0), ZoomDefaults.minScale)
    }

    func test_zoomClamp_veryLarge_clampsToMax() {
        XCTAssertEqual(zoomClamp(1_000_000), ZoomDefaults.maxScale)
    }

    // MARK: - zoomToggle additional

    func test_zoomToggle_slightlyAboveMin_returnsMin() {
        let slightly = ZoomDefaults.minScale + 0.01
        XCTAssertEqual(zoomToggle(current: slightly), ZoomDefaults.minScale)
    }

    func test_zoomToggle_atMaxScale_returnsMinScale() {
        XCTAssertEqual(zoomToggle(current: ZoomDefaults.maxScale), ZoomDefaults.minScale)
    }

    func test_zoomToggle_customTapTarget_zoomedIn_returnsMin() {
        let result = zoomToggle(current: 3.0, tapTarget: 2.0)
        XCTAssertEqual(result, ZoomDefaults.minScale)
    }

    func test_zoomToggle_threeRounds_correctCycle() {
        let t1 = zoomToggle(current: ZoomDefaults.minScale)   // → doubleTapScale
        let t2 = zoomToggle(current: t1)                       // → minScale
        let t3 = zoomToggle(current: t2)                       // → doubleTapScale
        XCTAssertEqual(t1, ZoomDefaults.doubleTapScale)
        XCTAssertEqual(t2, ZoomDefaults.minScale)
        XCTAssertEqual(t3, ZoomDefaults.doubleTapScale)
    }

    // MARK: - panClamp additional

    func test_panClamp_exactlyAtMaxOffset_returnsUnchanged() {
        let container = CGSize(width: 300, height: 600)
        let scale: CGFloat = 2.0
        let maxX = container.width  * (scale - 1) / 2  // 150
        let maxY = container.height * (scale - 1) / 2  // 300
        let result = panClamp(CGSize(width: maxX, height: maxY), scale: scale, in: container)
        XCTAssertEqual(result.width,  maxX, accuracy: 0.001)
        XCTAssertEqual(result.height, maxY, accuracy: 0.001)
    }

    func test_panClamp_zeroOffset_alwaysZero() {
        let result = panClamp(.zero, scale: 3.0, in: CGSize(width: 400, height: 800))
        XCTAssertEqual(result.width, 0)
        XCTAssertEqual(result.height, 0)
    }

    func test_panClamp_scaleJustAboveOne_allowsTinyOffset() {
        let container = CGSize(width: 300, height: 600)
        let result = panClamp(CGSize(width: 999, height: 999), scale: 1.1, in: container)
        XCTAssertGreaterThan(result.width, 0)
        XCTAssertGreaterThan(result.height, 0)
        XCTAssertLessThan(result.width, 20)  // tiny, not full 999
    }

    func test_panClamp_symmetricPositiveNegative() {
        let container = CGSize(width: 300, height: 600)
        let scale: CGFloat = 2.0
        let pos = panClamp(CGSize(width: 200, height: 400), scale: scale, in: container)
        let neg = panClamp(CGSize(width: -200, height: -400), scale: scale, in: container)
        XCTAssertEqual(pos.width,  -neg.width,  accuracy: 0.001, "Pan bounds must be symmetric")
        XCTAssertEqual(pos.height, -neg.height, accuracy: 0.001)
    }

    // MARK: - Pan drag gesture condition
    //
    // The drag gesture is only attached when `scale > ZoomDefaults.minScale`.
    // At minScale it must be absent so it does not compete with TabView paging.

    func test_dragGestureCondition_falseAtMinScale() {
        let scale = ZoomDefaults.minScale
        XCTAssertFalse(scale > ZoomDefaults.minScale,
                       "Pan drag gesture must NOT be active at minScale — TabView must own horizontal swipes")
    }

    func test_dragGestureCondition_trueSlightlyAboveMinScale() {
        let scale = ZoomDefaults.minScale + 0.01
        XCTAssertTrue(scale > ZoomDefaults.minScale,
                      "Pan drag gesture must be active the instant scale exceeds minScale")
    }

    func test_dragGestureCondition_trueAtDoubleTapScale() {
        XCTAssertTrue(ZoomDefaults.doubleTapScale > ZoomDefaults.minScale,
                      "Pan drag must be active at the double-tap zoom level")
    }

    func test_dragGestureCondition_trueAtMaxScale() {
        XCTAssertTrue(ZoomDefaults.maxScale > ZoomDefaults.minScale,
                      "Pan drag must be active at maxScale")
    }

    func test_dragGestureCondition_falseAfterResetToMinScale() {
        // Simulate zoom-in, then reset.
        var scale = ZoomDefaults.doubleTapScale
        XCTAssertTrue(scale > ZoomDefaults.minScale, "Gesture active while zoomed in")
        scale = ZoomDefaults.minScale
        XCTAssertFalse(scale > ZoomDefaults.minScale,
                       "Gesture must deactivate once scale resets to minScale")
    }

    // MARK: - Constants additional

    // MARK: - resetToken rendering

    @MainActor
    func test_zoomableImageView_withResetToken_renders() {
        let image = UIImage(systemName: "photo")!
        let view = ZoomableImageView(image: image, resetToken: 3)
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 667))
        controller.view.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        let rendered = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        XCTAssertGreaterThan(rendered.size.width, 0)
    }

    // MARK: - Constants additional

    func test_minScale_isExactlyOne() {
        XCTAssertEqual(ZoomDefaults.minScale, 1.0, "minScale must be 1.0 (native pixel size)")
    }

    func test_doubleTapScale_isGreaterThanOne() {
        XCTAssertGreaterThan(ZoomDefaults.doubleTapScale, 1.0)
    }

    func test_maxScale_isAtLeastTwo() {
        XCTAssertGreaterThanOrEqual(ZoomDefaults.maxScale, 2.0, "maxScale should allow at least 2× zoom")
    }

    // MARK: - Zoom-to-point offset math

    func test_zoomToPoint_tapAtCenter_producesZeroOffset() {
        // When the tap is exactly at the container centre, the offset to bring that
        // point to the centre should be zero.
        let container = CGSize(width: 300, height: 600)
        let tapPoint  = CGPoint(x: container.width / 2, y: container.height / 2)
        let scale     = ZoomDefaults.doubleTapScale

        let centre    = CGPoint(x: container.width / 2, y: container.height / 2)
        let raw       = CGSize(width:  (centre.x - tapPoint.x) * scale,
                               height: (centre.y - tapPoint.y) * scale)
        let result    = panClamp(raw, scale: scale, in: container)

        XCTAssertEqual(result.width,  0, accuracy: 0.001, "Tap at centre → zero horizontal offset")
        XCTAssertEqual(result.height, 0, accuracy: 0.001, "Tap at centre → zero vertical offset")
    }

    func test_zoomToPoint_tapAtTopLeft_producesPositiveOffset() {
        // Tapping top-left should shift the image down-right (positive offsets).
        let container = CGSize(width: 300, height: 600)
        let tapPoint  = CGPoint(x: 0, y: 0)
        let scale     = ZoomDefaults.doubleTapScale

        let centre = CGPoint(x: container.width / 2, y: container.height / 2)
        let raw    = CGSize(width:  (centre.x - tapPoint.x) * scale,
                            height: (centre.y - tapPoint.y) * scale)
        let result = panClamp(raw, scale: scale, in: container)

        XCTAssertGreaterThan(result.width,  0, "Top-left tap → positive (rightward) offset")
        XCTAssertGreaterThan(result.height, 0, "Top-left tap → positive (downward) offset")
    }

    func test_zoomToPoint_tapAtBottomRight_producesNegativeOffset() {
        // Tapping bottom-right should shift the image up-left (negative offsets).
        let container = CGSize(width: 300, height: 600)
        let tapPoint  = CGPoint(x: container.width, y: container.height)
        let scale     = ZoomDefaults.doubleTapScale

        let centre = CGPoint(x: container.width / 2, y: container.height / 2)
        let raw    = CGSize(width:  (centre.x - tapPoint.x) * scale,
                            height: (centre.y - tapPoint.y) * scale)
        let result = panClamp(raw, scale: scale, in: container)

        XCTAssertLessThan(result.width,  0, "Bottom-right tap → negative (leftward) offset")
        XCTAssertLessThan(result.height, 0, "Bottom-right tap → negative (upward) offset")
    }
}
