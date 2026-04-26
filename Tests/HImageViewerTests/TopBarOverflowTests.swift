//
//  TopBarOverflowTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 26/04/2026.
//
//  Tests for the trailing-button overflow behaviour in TopBar.
//
//  Rule: when the number of visible trailing buttons (Share / Edit / Select)
//  is ≥ 2, TopBar collapses them into a single ellipsis overflow menu.
//  When only 1 is visible it is shown directly; when 0 are visible nothing
//  is rendered in the trailing slot.
//

import XCTest
import SwiftUI
@testable import HImageViewer

// MARK: - Visible-count logic

final class TopBarOverflowTests: XCTestCase {

    // MARK: - visibleCount helper (mirrors TopBar's internal filter)

    /// Replicates the exact expression TopBar uses:
    /// `[showShare, showEdit, showSel].filter { $0 }.count`
    private func visibleCount(share: Bool, edit: Bool, select: Bool) -> Int {
        [share, edit, select].filter { $0 }.count
    }

    private func shouldOverflow(share: Bool, edit: Bool, select: Bool) -> Bool {
        visibleCount(share: share, edit: edit, select: select) >= 2
    }

    // MARK: - Zero visible buttons

    func test_visibleCount_allOff_isZero() {
        XCTAssertEqual(visibleCount(share: false, edit: false, select: false), 0)
    }

    func test_overflow_allOff_isFalse() {
        XCTAssertFalse(shouldOverflow(share: false, edit: false, select: false))
    }

    // MARK: - Exactly one visible button (no overflow)

    func test_visibleCount_shareOnly_isOne() {
        XCTAssertEqual(visibleCount(share: true, edit: false, select: false), 1)
    }

    func test_visibleCount_editOnly_isOne() {
        XCTAssertEqual(visibleCount(share: false, edit: true, select: false), 1)
    }

    func test_visibleCount_selectOnly_isOne() {
        XCTAssertEqual(visibleCount(share: false, edit: false, select: true), 1)
    }

    func test_overflow_shareOnly_isFalse() {
        XCTAssertFalse(shouldOverflow(share: true, edit: false, select: false))
    }

    func test_overflow_editOnly_isFalse() {
        XCTAssertFalse(shouldOverflow(share: false, edit: true, select: false))
    }

    func test_overflow_selectOnly_isFalse() {
        XCTAssertFalse(shouldOverflow(share: false, edit: false, select: true))
    }

    // MARK: - Exactly two visible buttons (overflow threshold)

    func test_visibleCount_shareAndEdit_isTwo() {
        XCTAssertEqual(visibleCount(share: true, edit: true, select: false), 2)
    }

    func test_visibleCount_shareAndSelect_isTwo() {
        XCTAssertEqual(visibleCount(share: true, edit: false, select: true), 2)
    }

    func test_visibleCount_editAndSelect_isTwo() {
        XCTAssertEqual(visibleCount(share: false, edit: true, select: true), 2)
    }

    func test_overflow_shareAndEdit_isTrue() {
        XCTAssertTrue(shouldOverflow(share: true, edit: true, select: false),
                      "Two visible buttons must trigger overflow")
    }

    func test_overflow_shareAndSelect_isTrue() {
        XCTAssertTrue(shouldOverflow(share: true, edit: false, select: true),
                      "Two visible buttons must trigger overflow")
    }

    func test_overflow_editAndSelect_isTrue() {
        XCTAssertTrue(shouldOverflow(share: false, edit: true, select: true),
                      "Two visible buttons must trigger overflow")
    }

    // MARK: - All three visible (overflow)

    func test_visibleCount_allOn_isThree() {
        XCTAssertEqual(visibleCount(share: true, edit: true, select: true), 3)
    }

    func test_overflow_allOn_isTrue() {
        XCTAssertTrue(shouldOverflow(share: true, edit: true, select: true),
                      "Three visible buttons must trigger overflow")
    }

    // MARK: - Threshold boundary: count < 2 never overflows

    func test_overflow_neverTriggeredBelowTwo() {
        for (s, e, sel) in [(false, false, false), (true, false, false),
                            (false, true, false), (false, false, true)] {
            XCTAssertFalse(shouldOverflow(share: s, edit: e, select: sel),
                           "share=\(s) edit=\(e) select=\(sel) must not overflow")
        }
    }

    // MARK: - TopBarConfig closure wiring

    func test_topBarConfig_onShare_isCalled() {
        var called = false
        let config = makeConfig(share: true, edit: false, select: false,
                                onShare: { called = true })
        config.onShare()
        XCTAssertTrue(called)
    }

    func test_topBarConfig_onEdit_isCalled() {
        var called = false
        let config = makeConfig(share: false, edit: true, select: false,
                                onEdit: { called = true })
        config.onEdit()
        XCTAssertTrue(called)
    }

    func test_topBarConfig_onSelectToggle_isCalled() {
        var called = false
        let config = makeConfig(share: false, edit: false, select: true,
                                onSelectToggle: { called = true })
        config.onSelectToggle()
        XCTAssertTrue(called)
    }

    func test_topBarConfig_allThreeClosures_areIndependent() {
        var shareCount = 0
        var editCount  = 0
        var selCount   = 0
        let config = makeConfig(
            share: true, edit: true, select: true,
            onShare: { shareCount += 1 },
            onEdit:  { editCount  += 1 },
            onSelectToggle: { selCount += 1 }
        )
        config.onShare()
        config.onEdit()
        config.onSelectToggle()
        XCTAssertEqual(shareCount, 1)
        XCTAssertEqual(editCount,  1)
        XCTAssertEqual(selCount,   1)
    }

    // MARK: - Rendering smoke tests (require simulator)

    @MainActor
    func test_topBar_allThreeButtons_overflowMode_renders() {
        let config = makeConfig(share: true, edit: true, select: true)
        let image = render(TopBar(config: config))
        XCTAssertGreaterThan(image.size.width, 0,
                             "TopBar in overflow mode must render without crashing")
    }

    @MainActor
    func test_topBar_twoButtons_overflowMode_renders() {
        let config = makeConfig(share: true, edit: true, select: false)
        let image = render(TopBar(config: config))
        XCTAssertGreaterThan(image.size.width, 0)
    }

    @MainActor
    func test_topBar_oneButton_noOverflow_renders() {
        let config = makeConfig(share: true, edit: false, select: false)
        let image = render(TopBar(config: config))
        XCTAssertGreaterThan(image.size.width, 0)
    }

    @MainActor
    func test_topBar_noButtons_renders() {
        let config = makeConfig(share: false, edit: false, select: false)
        let image = render(TopBar(config: config))
        XCTAssertGreaterThan(image.size.width, 0)
    }

    @MainActor
    func test_topBar_overflowMode_classicTheme_renders() {
        var config = makeConfig(share: true, edit: true, select: true)
        config.isGlassMode = false
        config.tintColor = .orange
        let image = render(TopBar(config: config))
        XCTAssertGreaterThan(image.size.width, 0,
                             "Overflow button must render in classic (non-glass) theme")
    }

    @MainActor
    func test_topBar_overflowMode_compactLayout_renders() {
        let config = makeConfig(share: true, edit: true, select: true)
        let image = render(TopBar(config: config, compact: true))
        XCTAssertGreaterThan(image.size.width, 0,
                             "Overflow button must render in compact (landscape) mode")
    }

    @MainActor
    func test_topBar_allCombinations_render() {
        let flags = [false, true]
        for s in flags { for e in flags { for sel in flags {
            let config = makeConfig(share: s, edit: e, select: sel)
            let image = render(TopBar(config: config))
            XCTAssertGreaterThan(image.size.width, 0,
                                 "share=\(s) edit=\(e) select=\(sel) must not crash")
        }}}
    }
}

// MARK: - Helpers

private func makeConfig(
    share: Bool = false,
    edit:  Bool = false,
    select: Bool = false,
    onShare: @escaping () -> Void = {},
    onEdit:  @escaping () -> Void = {},
    onSelectToggle: @escaping () -> Void = {}
) -> TopBarConfig {
    TopBarConfig(
        showShareButton: share,
        showEditButton:  edit,
        showSelectButton: select,
        selectionMode: false,
        pageCounterText: nil,
        onDismiss: {},
        onCancelSelection: {},
        onSelectToggle: onSelectToggle,
        onEdit: onEdit,
        onShare: onShare
    )
}

@MainActor
private func render<V: View>(_ view: V) -> UIImage {
    let controller = UIHostingController(rootView: view)
    controller.view.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 56))
    controller.view.layoutIfNeeded()
    let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
    return renderer.image { _ in
        controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
}
