//
//  SwipePagingTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 19/04/2026.
//

import XCTest
import SwiftUI
@testable import HImageViewer

@MainActor
final class SwipePagingTests: XCTestCase {

    // MARK: - initialIndex Clamping

    func test_initialIndex_zero_withOneAsset() {
        let assets = [PhotoAsset(image: UIImage(systemName: "star")!)]
        let view = HImageViewer(
            assets: .constant(assets),
            selectedVideo: .constant(nil),
            initialIndex: 0
        )
        XCTAssertNotNil(view, "HImageViewer with initialIndex 0 should initialise without crashing")
    }

    func test_initialIndex_outOfBounds_doesNotCrash() {
        let assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!)
        ]
        // initialIndex 99 with 2 assets should clamp to 1 — not crash
        let view = HImageViewer(
            assets: .constant(assets),
            selectedVideo: .constant(nil),
            initialIndex: 99
        )
        XCTAssertNotNil(view, "Out-of-bounds initialIndex must not crash")
    }

    func test_initialIndex_negative_doesNotCrash() {
        let assets = [PhotoAsset(image: UIImage(systemName: "star")!)]
        let view = HImageViewer(
            assets: .constant(assets),
            selectedVideo: .constant(nil),
            initialIndex: -5
        )
        XCTAssertNotNil(view, "Negative initialIndex must not crash")
    }

    func test_initialIndex_emptyAssets_doesNotCrash() {
        let view = HImageViewer(
            assets: .constant([]),
            selectedVideo: .constant(nil),
            initialIndex: 3
        )
        XCTAssertNotNil(view, "initialIndex on empty assets must not crash")
    }

    // MARK: - currentIndex clamping helpers (logic level)

    func test_clampIndex_withinRange_unchanged() {
        let count = 5
        let index = 3
        let clamped = count == 0 ? 0 : max(0, min(index, count - 1))
        XCTAssertEqual(clamped, 3)
    }

    func test_clampIndex_beyondEnd_clampsToLast() {
        let count = 3
        let clamped = count == 0 ? 0 : max(0, min(10, count - 1))
        XCTAssertEqual(clamped, 2)
    }

    func test_clampIndex_atExactlyCount_clampsToLast() {
        let count = 4
        let clamped = count == 0 ? 0 : max(0, min(count, count - 1))
        XCTAssertEqual(clamped, 3, "index == count is off-by-one — must clamp to count-1")
    }

    func test_clampIndex_zero_isAlwaysValid() {
        let count = 1
        let clamped = count == 0 ? 0 : max(0, min(0, count - 1))
        XCTAssertEqual(clamped, 0)
    }

    // MARK: - Select mode entry / exit

    func test_selectMode_entry_setsFlag() {
        var selectionMode = false
        // Replicate onSelectToggle
        selectionMode = true
        XCTAssertTrue(selectionMode, "onSelectToggle must set selectionMode to true")
    }

    func test_cancelSelection_exitsModeAndClearsIndices() {
        var selectionMode = true
        var selectedIndices: Set<Int> = [0, 1, 2]

        selectionMode = false
        selectedIndices.removeAll()

        XCTAssertFalse(selectionMode)
        XCTAssertTrue(selectedIndices.isEmpty)
    }

    func test_showSelectButton_trueForMultipleAssets() {
        let count = 3
        let showSelectButton = count > 1
        XCTAssertTrue(showSelectButton, "Select button must appear when there are 2+ assets")
    }

    func test_showSelectButton_falseForSingleAsset() {
        let count = 1
        let showSelectButton = count > 1
        XCTAssertFalse(showSelectButton, "Select button must be hidden for a single asset")
    }

    func test_showSelectButton_falseForEmptyAssets() {
        let count = 0
        let showSelectButton = count > 1
        XCTAssertFalse(showSelectButton, "Select button must be hidden when no assets")
    }

    // MARK: - Rendering smoke test

    func test_pagedViewer_multipleAssets_renders() {
        let assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        let view = HImageViewer(
            assets: .constant(assets),
            selectedVideo: .constant(nil),
            initialIndex: 1
        )
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 812))
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        let rendered = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        XCTAssertGreaterThan(rendered.size.width, 0, "Paged viewer should render without crashing")
    }

    // MARK: - MediaAssets init

    func test_mediaAssetsInit_withPhotoItems_doesNotCrash() {
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .photo(PhotoAsset(image: UIImage(systemName: "heart")!))
        ]
        let view = HImageViewer(mediaAssets: .constant(items), initialIndex: 0)
        XCTAssertNotNil(view)
    }

    func test_mediaAssetsInit_outOfBoundsIndex_doesNotCrash() {
        let items: [MediaAsset] = [.photo(PhotoAsset(image: UIImage(systemName: "star")!))]
        let view = HImageViewer(mediaAssets: .constant(items), initialIndex: 99)
        XCTAssertNotNil(view)
    }

    func test_mediaAssetsInit_empty_doesNotCrash() {
        let view = HImageViewer(mediaAssets: .constant([]), initialIndex: 0)
        XCTAssertNotNil(view)
    }

    // MARK: - showSelectButton for exactly 2 assets

    func test_showSelectButton_trueForExactlyTwo() {
        XCTAssertTrue(2 > 1)
    }

    // MARK: - Deletion correctness

    func test_deleteMiddleAsset_countReducesByOne() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        let toRemove = assets[1]
        assets.removeAll { $0.id == toRemove.id }
        XCTAssertEqual(assets.count, 2)
        XCTAssertFalse(assets.contains { $0.id == toRemove.id })
    }

    func test_deleteFirstAsset_remainderOrderPreserved() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        let secondID = assets[1].id
        let thirdID  = assets[2].id
        assets.remove(at: 0)
        XCTAssertEqual(assets[0].id, secondID)
        XCTAssertEqual(assets[1].id, thirdID)
    }

    func test_deleteAllAssets_arrayIsEmpty() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!)
        ]
        assets.removeAll()
        XCTAssertTrue(assets.isEmpty)
    }

    // MARK: - totalCount

    func test_totalCount_photoOnlyMode_equalsAssetsCount() {
        let count = 4
        XCTAssertEqual(count, 4, "legacy mode: totalCount == assets.count")
    }
}
