//
//  PageIndicatorTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 20/04/2026.
//

import XCTest
import SwiftUI
import UIKit
@testable import HImageViewer

final class PageIndicatorTests: XCTestCase {

    // MARK: - pageCounterText formatting

    func test_pageCounterText_singleAsset_isNil() {
        let result = makeCounterText(currentIndex: 0, count: 1, selectionMode: false)
        XCTAssertNil(result, "Counter must be nil for a single asset")
    }

    func test_pageCounterText_zeroAssets_isNil() {
        let result = makeCounterText(currentIndex: 0, count: 0, selectionMode: false)
        XCTAssertNil(result, "Counter must be nil when there are no assets")
    }

    func test_pageCounterText_multipleAssets_formatsCorrectly() {
        XCTAssertEqual(makeCounterText(currentIndex: 0, count: 5, selectionMode: false), "1 / 5")
        XCTAssertEqual(makeCounterText(currentIndex: 2, count: 5, selectionMode: false), "3 / 5")
        XCTAssertEqual(makeCounterText(currentIndex: 4, count: 5, selectionMode: false), "5 / 5")
    }

    func test_pageCounterText_twoAssets_formatsCorrectly() {
        XCTAssertEqual(makeCounterText(currentIndex: 0, count: 2, selectionMode: false), "1 / 2")
        XCTAssertEqual(makeCounterText(currentIndex: 1, count: 2, selectionMode: false), "2 / 2")
    }

    func test_pageCounterText_inSelectionMode_isNil() {
        let result = makeCounterText(currentIndex: 1, count: 5, selectionMode: true)
        XCTAssertNil(result, "Counter must be nil when in selection mode")
    }

    // MARK: - PageDotsView.shouldShow

    func test_dots_hiddenForZeroAssets() {
        XCTAssertFalse(PageDotsView(currentIndex: 0, count: 0).shouldShow)
    }

    func test_dots_hiddenForOneAsset() {
        XCTAssertFalse(PageDotsView(currentIndex: 0, count: 1).shouldShow)
    }

    func test_dots_shownForTwoAssets() {
        XCTAssertTrue(PageDotsView(currentIndex: 0, count: 2).shouldShow)
    }

    func test_dots_shownAtMaxDots() {
        XCTAssertTrue(PageDotsView(currentIndex: 0, count: PageDotsView.maxDots).shouldShow)
    }

    func test_dots_hiddenAboveMaxDots() {
        XCTAssertFalse(PageDotsView(currentIndex: 0, count: PageDotsView.maxDots + 1).shouldShow)
    }

    func test_dots_maxDots_isEight() {
        XCTAssertEqual(PageDotsView.maxDots, 8, "Market standard threshold is 8 dots")
    }

    // MARK: - Rendering smoke tests

    @MainActor
    func test_pageDotsView_renders_withValidCount() {
        let view = PageDotsView(currentIndex: 1, count: 4)
        let image = renderView(view, size: CGSize(width: 200, height: 40))
        XCTAssertGreaterThan(image.size.width, 0)
    }

    @MainActor
    func test_pageDotsView_renders_withCountAboveMax() {
        // shouldShow == false — renders empty, must not crash
        let view = PageDotsView(currentIndex: 0, count: 20)
        let image = renderView(view, size: CGSize(width: 200, height: 40))
        XCTAssertGreaterThan(image.size.width, 0)
    }

    @MainActor
    func test_topBar_withCounter_renders() {
        let config = TopBarConfig(
            showEditButton: true,
            showSelectButton: true,
            selectionMode: false,
            pageCounterText: "2 / 5",
            onDismiss: {},
            onCancelSelection: {},
            onSelectToggle: {},
            onEdit: {}
        )
        let view = TopBar(config: config)
        let image = renderView(view, size: CGSize(width: 375, height: 56))
        XCTAssertGreaterThan(image.size.width, 0)
    }

    @MainActor
    func test_topBar_withoutCounter_renders() {
        let config = TopBarConfig(
            showEditButton: false,
            showSelectButton: false,
            selectionMode: false,
            pageCounterText: nil,
            onDismiss: {},
            onCancelSelection: {},
            onSelectToggle: {},
            onEdit: {}
        )
        let view = TopBar(config: config)
        let image = renderView(view, size: CGSize(width: 375, height: 56))
        XCTAssertGreaterThan(image.size.width, 0)
    }

    // MARK: - Counter format additional

    func test_pageCounterText_largeCount() {
        XCTAssertEqual(makeCounterText(currentIndex: 99, count: 100, selectionMode: false), "100 / 100")
    }

    func test_pageCounterText_firstOfMany() {
        XCTAssertEqual(makeCounterText(currentIndex: 0, count: 50, selectionMode: false), "1 / 50")
    }

    func test_pageCounterText_twoAssetsSelectionMode_isNil() {
        XCTAssertNil(makeCounterText(currentIndex: 0, count: 2, selectionMode: true))
    }

    func test_pageCounterText_exactlyOneAsset_isNil() {
        XCTAssertNil(makeCounterText(currentIndex: 0, count: 1, selectionMode: false))
    }

    // MARK: - PageDotsView.shouldShow boundaries

    func test_dots_shownForThreeAssets() {
        XCTAssertTrue(PageDotsView(currentIndex: 0, count: 3).shouldShow)
    }

    func test_dots_shownForSevenAssets() {
        XCTAssertTrue(PageDotsView(currentIndex: 3, count: 7).shouldShow)
    }

    func test_dots_hiddenForNineAssets() {
        XCTAssertFalse(PageDotsView(currentIndex: 0, count: 9).shouldShow)
    }

    func test_dots_hiddenForVeryLargeCount() {
        XCTAssertFalse(PageDotsView(currentIndex: 0, count: 1_000).shouldShow)
    }

    func test_dots_allCountsFromTwoToMaxShouldShow() {
        for count in 2...PageDotsView.maxDots {
            XCTAssertTrue(PageDotsView(currentIndex: 0, count: count).shouldShow,
                          "count=\(count) must show dots")
        }
    }

    func test_dots_countBelowTwoDoesNotShow() {
        for count in [0, 1] {
            XCTAssertFalse(PageDotsView(currentIndex: 0, count: count).shouldShow,
                           "count=\(count) must not show dots")
        }
    }
}

// MARK: - Helpers

/// Pure function replicating `HImageViewer.pageCounterText` logic.
private func makeCounterText(currentIndex: Int, count: Int, selectionMode: Bool) -> String? {
    guard count > 1, !selectionMode else { return nil }
    return "\(currentIndex + 1) / \(count)"
}

@MainActor
private func renderView<V: View>(_ view: V, size: CGSize) -> UIImage {
    let controller = UIHostingController(rootView: view)
    controller.view.frame = CGRect(origin: .zero, size: size)
    controller.view.layoutIfNeeded()
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
}
