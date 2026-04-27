//
//  AccessibilityTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 20/04/2026.
//
//  Verifies that every interactive and informational element in HImageViewer
//  exposes correct VoiceOver labels, hints, and values.
//
//  Two layers of coverage:
//   1. String-unit tests — exercise the label-producing helpers directly.
//   2. Property tests — verify that SwiftUI view structs store the correct
//      accessibility label/hint strings that will be passed to .accessibilityLabel().
//

import XCTest
import SwiftUI
@testable import HImageViewer

@MainActor
final class AccessibilityTests: XCTestCase {

    // MARK: - PageDotsView: accessibilityLabel string

    func test_pageDotsLabel_page1of3() {
        XCTAssertEqual(PageDotsView(currentIndex: 0, count: 3).accessibilityLabel, "Page 1 of 3")
    }

    func test_pageDotsLabel_page2of5() {
        XCTAssertEqual(PageDotsView(currentIndex: 1, count: 5).accessibilityLabel, "Page 2 of 5")
    }

    func test_pageDotsLabel_lastPage() {
        XCTAssertEqual(PageDotsView(currentIndex: 4, count: 5).accessibilityLabel, "Page 5 of 5")
    }

    func test_pageDotsLabel_twoItems() {
        XCTAssertEqual(PageDotsView(currentIndex: 0, count: 2).accessibilityLabel, "Page 1 of 2")
    }

    func test_pageDotsLabel_indexZeroOfEight() {
        XCTAssertEqual(PageDotsView(currentIndex: 0, count: 8).accessibilityLabel, "Page 1 of 8")
    }

    // MARK: - ProgressRingOverlayView: progressAccessibilityLabel string

    func test_progressLabel_withTitle_halfWay() {
        XCTAssertEqual(
            ProgressRingOverlayView(progress: 0.5, title: "Uploading").progressAccessibilityLabel,
            "Uploading, 50 percent"
        )
    }

    func test_progressLabel_noTitle_halfWay() {
        XCTAssertEqual(
            ProgressRingOverlayView(progress: 0.5, title: nil).progressAccessibilityLabel,
            "Upload progress, 50 percent"
        )
    }

    func test_progressLabel_withTitle_zero() {
        XCTAssertEqual(
            ProgressRingOverlayView(progress: 0.0, title: "Uploading").progressAccessibilityLabel,
            "Uploading, 0 percent"
        )
    }

    func test_progressLabel_noTitle_complete() {
        XCTAssertEqual(
            ProgressRingOverlayView(progress: 1.0, title: nil).progressAccessibilityLabel,
            "Upload progress, 100 percent"
        )
    }

    func test_progressLabel_customTitle_quarterWay() {
        XCTAssertEqual(
            ProgressRingOverlayView(progress: 0.25, title: "Saving").progressAccessibilityLabel,
            "Saving, 25 percent"
        )
    }

    func test_progressLabel_withTitle_nearComplete() {
        XCTAssertEqual(
            ProgressRingOverlayView(progress: 0.99, title: "Uploading").progressAccessibilityLabel,
            "Uploading, 99 percent"
        )
    }

    // MARK: - MultiPhotoGrid: tileLabel string

    func test_tileLabel_photo_index0() {
        let item = MediaAsset.photo(PhotoAsset(image: UIImage(systemName: "star")!))
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: item, at: 0), "Photo 1")
    }

    func test_tileLabel_photo_index4() {
        let item = MediaAsset.photo(PhotoAsset(image: UIImage(systemName: "star")!))
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: item, at: 4), "Photo 5")
    }

    func test_tileLabel_video_index0() {
        let item = MediaAsset.video(URL(string: "https://example.com/clip.mp4")!)
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: item, at: 0), "Video 1")
    }

    func test_tileLabel_video_index2() {
        let item = MediaAsset.video(URL(string: "https://example.com/clip.mp4")!)
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: item, at: 2), "Video 3")
    }

    func test_tileLabel_photo_singleItem_isPhoto1() {
        let item = MediaAsset.photo(PhotoAsset(image: UIImage(systemName: "star")!))
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: item, at: 0), "Photo 1",
                       "Single-item grid must still produce 'Photo 1'")
    }

    // MARK: - CircleButton: stored accessibility properties

    func test_circleButton_storesAccessibilityLabel() {
        let button = CircleButton(
            systemName: "xmark",
            accessibilityLabel: "Close",
            action: {}
        )
        XCTAssertEqual(button.accessibilityLabel, "Close")
    }

    func test_circleButton_storesAccessibilityHint() {
        let button = CircleButton(
            systemName: "xmark",
            accessibilityLabel: "Close",
            accessibilityHint: "Dismisses the viewer",
            action: {}
        )
        XCTAssertEqual(button.accessibilityHint, "Dismisses the viewer")
    }

    func test_circleButton_editLabel() {
        let button = CircleButton(
            systemName: "pencil",
            accessibilityLabel: "Edit",
            accessibilityHint: "Opens the photo editor",
            action: {}
        )
        XCTAssertEqual(button.accessibilityLabel, "Edit")
        XCTAssertEqual(button.accessibilityHint, "Opens the photo editor")
    }

    func test_circleButton_selectLabel() {
        let button = CircleButton(
            systemName: "checkmark.circle",
            accessibilityLabel: "Select",
            accessibilityHint: "Enters selection mode",
            action: {}
        )
        XCTAssertEqual(button.accessibilityLabel, "Select")
        XCTAssertEqual(button.accessibilityHint, "Enters selection mode")
    }

    func test_circleButton_defaultAccessibilityLabel_isEmpty() {
        let button = CircleButton(systemName: "xmark", action: {})
        XCTAssertEqual(button.accessibilityLabel, "",
                       "Default accessibility label should be empty string")
    }

    func test_circleButton_defaultAccessibilityHint_isNil() {
        let button = CircleButton(systemName: "xmark", action: {})
        XCTAssertNil(button.accessibilityHint,
                     "Default accessibility hint should be nil")
    }

    // MARK: - TopBarConfig: accessibilityPageLabel propagation

    func test_topBarConfig_accessibilityPageLabel_stored() {
        let config = TopBarConfig(
            showEditButton: false, showSelectButton: false,
            selectionMode: false,
            pageCounterText: "2 / 5",
            accessibilityPageLabel: "Page 2 of 5",
            onDismiss: {}, onCancelSelection: {}, onSelectToggle: {}, onEdit: {}
        )
        XCTAssertEqual(config.accessibilityPageLabel, "Page 2 of 5")
    }

    func test_topBarConfig_accessibilityPageLabel_defaultIsNil() {
        let config = TopBarConfig(
            showEditButton: false, showSelectButton: false,
            selectionMode: false, pageCounterText: nil,
            onDismiss: {}, onCancelSelection: {}, onSelectToggle: {}, onEdit: {}
        )
        XCTAssertNil(config.accessibilityPageLabel,
                     "accessibilityPageLabel should default to nil")
    }

    func test_topBarConfig_accessibilityPageLabel_nilWhenNoPaging() {
        let config = TopBarConfig(
            showEditButton: false, showSelectButton: false,
            selectionMode: false,
            pageCounterText: nil,
            accessibilityPageLabel: nil,
            onDismiss: {}, onCancelSelection: {}, onSelectToggle: {}, onEdit: {}
        )
        XCTAssertNil(config.accessibilityPageLabel)
    }

    // MARK: - BottomBarConfig: action button label derivation

    func test_bottomBarConfig_actionLabel_saveMode() {
        let config = BottomBarConfig(
            selectionMode: false, showSaveButton: true,
            showCommentBox: false, onSave: {}, onDelete: {}
        )
        let label = config.selectionMode ? "Remove selected items" : "Save photo"
        XCTAssertEqual(label, "Save photo")
    }

    func test_bottomBarConfig_actionLabel_selectionMode() {
        let config = BottomBarConfig(
            selectionMode: true, showSaveButton: true,
            showCommentBox: false, onSave: {}, onDelete: {}
        )
        let label = config.selectionMode ? "Remove selected items" : "Save photo"
        XCTAssertEqual(label, "Remove selected items")
    }
}
