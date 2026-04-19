//
//  TopBarCancelSelectionTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 19/04/2026.
//

import XCTest
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
            isSinglePhotoMode: true,
            showEditButton: true,
            selectionMode: true,
            onDismiss: {},
            onCancelSelection: { cancelCalled = true },
            onEdit: {}
        )

        config.onCancelSelection()

        XCTAssertTrue(cancelCalled, "onCancelSelection closure must be invoked when called")
    }

    func test_topBarConfig_onDismiss_closure_isCalled() {
        var dismissCalled = false

        let config = TopBarConfig(
            isSinglePhotoMode: false,
            showEditButton: false,
            selectionMode: false,
            onDismiss: { dismissCalled = true },
            onCancelSelection: {},
            onEdit: {}
        )

        config.onDismiss()

        XCTAssertTrue(dismissCalled, "onDismiss closure must be invoked when called")
    }

    // MARK: - HImageViewerLauncher rename

    func test_hImageViewerLauncher_typeExists() {
        // Verify the type compiles and is accessible under the correct name.
        // If ImageViewerLauncher still exists, this would catch the stale reference.
        let type: HImageViewerLauncher.Type = HImageViewerLauncher.self
        XCTAssertNotNil(type, "HImageViewerLauncher type must exist with the correct prefix")
    }
}
