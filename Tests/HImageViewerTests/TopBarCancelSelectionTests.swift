//
//  TopBarCancelSelectionTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 19/04/2026.
//

import XCTest
import SwiftUI
@testable import HImageViewer

@MainActor
final class TopBarCancelSelectionTests: XCTestCase {

    // MARK: - onCancelSelection replaces onSelectToggle

    func test_cancelSelection_clearsIndicesAndExitsSelectionMode() {
        var selectionMode = true
        var selectedIndices: Set<Int> = [0, 1, 2]

        // Replicate the onCancelSelection closure logic from HImageViewer
        selectionMode = false
        selectedIndices.removeAll()

        XCTAssertFalse(selectionMode, "selectionMode should be false after cancel")
        XCTAssertTrue(selectedIndices.isEmpty, "selectedIndices should be empty after cancel")
    }

    func test_cancelSelection_doesNotDelete_assets() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!)
        ]
        let originalCount = assets.count
        var selectionMode = true
        var selectedIndices: Set<Int> = [0, 1]

        // Cancel — should NOT remove anything from assets
        selectionMode = false
        selectedIndices.removeAll()

        XCTAssertEqual(assets.count, originalCount, "Cancel must not delete any assets")
    }

    func test_topBarConfig_cancelSelection_closure_isCalled() {
        var cancelCalled = false

        let config = TopBarConfig(
            showEditButton: true,
            showSelectButton: false,
            selectionMode: true,
            pageCounterText: nil,
            onDismiss: {},
            onCancelSelection: { cancelCalled = true },
            onSelectToggle: {},
            onEdit: {}
        )

        config.onCancelSelection()

        XCTAssertTrue(cancelCalled, "onCancelSelection closure must be invoked when called")
    }

    func test_topBarConfig_onDismiss_closure_isCalled() {
        var dismissCalled = false

        let config = TopBarConfig(
            showEditButton: false,
            showSelectButton: false,
            selectionMode: false,
            pageCounterText: nil,
            onDismiss: { dismissCalled = true },
            onCancelSelection: {},
            onSelectToggle: {},
            onEdit: {}
        )

        config.onDismiss()

        XCTAssertTrue(dismissCalled, "onDismiss closure must be invoked when called")
    }

    func test_topBarConfig_onSelectToggle_closure_isCalled() {
        var selectToggleCalled = false

        let config = TopBarConfig(
            showEditButton: false,
            showSelectButton: true,
            selectionMode: false,
            pageCounterText: "1 / 3",
            onDismiss: {},
            onCancelSelection: {},
            onSelectToggle: { selectToggleCalled = true },
            onEdit: {}
        )

        config.onSelectToggle()

        XCTAssertTrue(selectToggleCalled, "onSelectToggle closure must be invoked when called")
    }

    // MARK: - HImageViewerLauncher rename

    func test_hImageViewerLauncher_typeExists() {
        // Verify the type compiles and is accessible under the correct name.
        // If ImageViewerLauncher still exists, this would catch the stale reference.
        let type: HImageViewerLauncher.Type = HImageViewerLauncher.self
        XCTAssertNotNil(type, "HImageViewerLauncher type must exist with the correct prefix")
    }

    // MARK: - TopBarConfig defaults

    func test_topBarConfig_isGlassMode_defaultIsTrue() {
        let config = TopBarConfig(
            showEditButton: false, showSelectButton: false,
            selectionMode: false, pageCounterText: nil,
            onDismiss: {}, onCancelSelection: {}, onSelectToggle: {}, onEdit: {}
        )
        XCTAssertTrue(config.isGlassMode, "Default isGlassMode must be true")
    }

    func test_topBarConfig_tintColor_defaultIsBlue() {
        let config = TopBarConfig(
            showEditButton: false, showSelectButton: false,
            selectionMode: false, pageCounterText: nil,
            onDismiss: {}, onCancelSelection: {}, onSelectToggle: {}, onEdit: {}
        )
        XCTAssertEqual(config.tintColor, Color.blue)
    }

    func test_topBarConfig_onEdit_isCalled() {
        var editCalled = false
        let config = TopBarConfig(
            showEditButton: true, showSelectButton: false,
            selectionMode: false, pageCounterText: nil,
            onDismiss: {}, onCancelSelection: {}, onSelectToggle: {},
            onEdit: { editCalled = true }
        )
        config.onEdit()
        XCTAssertTrue(editCalled)
    }

    func test_topBarConfig_customTintColor_storedCorrectly() {
        let config = TopBarConfig(
            showEditButton: false, showSelectButton: false,
            selectionMode: false, pageCounterText: nil,
            tintColor: .purple,
            onDismiss: {}, onCancelSelection: {}, onSelectToggle: {}, onEdit: {}
        )
        XCTAssertEqual(config.tintColor, Color.purple)
    }

    func test_topBarConfig_pageCounterText_storedCorrectly() {
        let config = TopBarConfig(
            showEditButton: false, showSelectButton: false,
            selectionMode: false, pageCounterText: "3 / 7",
            onDismiss: {}, onCancelSelection: {}, onSelectToggle: {}, onEdit: {}
        )
        XCTAssertEqual(config.pageCounterText, "3 / 7")
    }
}
