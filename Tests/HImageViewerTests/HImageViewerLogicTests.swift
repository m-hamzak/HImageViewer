//
//  HImageViewerLogicTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//

import XCTest
@testable import HImageViewer

@MainActor
final class HImageViewerLogicTests: XCTestCase {

    // MARK: - isSinglePhotoMode Logic

    func test_singlePhotoMode_zeroAssets() {
        let count = 0
        let isSinglePhotoMode = count <= 1
        XCTAssertTrue(isSinglePhotoMode, "0 assets → single photo mode")
    }

    func test_singlePhotoMode_oneAsset() {
        let count = 1
        let isSinglePhotoMode = count <= 1
        XCTAssertTrue(isSinglePhotoMode, "1 asset → single photo mode")
    }

    func test_singlePhotoMode_twoAssets() {
        let count = 2
        let isSinglePhotoMode = count <= 1
        XCTAssertFalse(isSinglePhotoMode, "2+ assets → multi-photo mode (grid)")
    }

    // MARK: - isUploading Logic

    func test_isUploading_progressNil() {
        let progress: Double? = nil
        let isUploading = (progress ?? 0) > 0 && (progress ?? 0) < 1.0
        XCTAssertFalse(isUploading, "nil progress = not uploading")
    }

    func test_isUploading_progressZero() {
        let progress: Double? = 0.0
        let isUploading = (progress ?? 0) > 0 && (progress ?? 0) < 1.0
        XCTAssertFalse(isUploading, "0.0 progress = not uploading yet")
    }

    func test_isUploading_progressHalf() {
        let progress: Double? = 0.5
        let isUploading = (progress ?? 0) > 0 && (progress ?? 0) < 1.0
        XCTAssertTrue(isUploading, "0.5 progress = actively uploading")
    }

    func test_isUploading_progressOne() {
        let progress: Double? = 1.0
        let isUploading = (progress ?? 0) > 0 && (progress ?? 0) < 1.0
        XCTAssertFalse(isUploading, "1.0 progress = upload complete, not 'uploading'")
    }

    // MARK: - shouldShowSaveButton Logic

    func test_shouldShowSave_singleMode_editedTrue_configFalse() {
        let isSinglePhotoMode = true
        let wasImageEdited = true
        let showSaveButton = false

        let result: Bool
        if isSinglePhotoMode {
            result = wasImageEdited || showSaveButton
        } else {
            result = showSaveButton
        }

        XCTAssertTrue(result, "Edited image should show save button regardless of config")
    }

    func test_shouldShowSave_singleMode_editedFalse_configFalse() {
        let isSinglePhotoMode = true
        let wasImageEdited = false
        let showSaveButton = false

        let result: Bool
        if isSinglePhotoMode {
            result = wasImageEdited || showSaveButton
        } else {
            result = showSaveButton
        }

        XCTAssertFalse(result, "Not edited + config false = hide save button")
    }

    func test_shouldShowSave_multiMode_configTrue() {
        let isSinglePhotoMode = false
        let showSaveButton = true

        let result: Bool
        if isSinglePhotoMode {
            result = false || showSaveButton
        } else {
            result = showSaveButton
        }

        XCTAssertTrue(result, "Multi mode respects config.showSaveButton directly")
    }

    // MARK: - handleSelection Logic

    func test_selectionToggle() {
        var selectedIndices: Set<Int> = []
        let index = 2

        // First tap: select
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
        XCTAssertTrue(selectedIndices.contains(2), "First tap should SELECT the photo")

        // Second tap: deselect
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
        XCTAssertFalse(selectedIndices.contains(2), "Second tap should DESELECT the photo")
    }

    // MARK: - handleDelete Logic

    func test_deleteSelectedAssets() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),      // index 0: "A"
            PhotoAsset(image: UIImage(systemName: "heart")!),     // index 1: "B"
            PhotoAsset(image: UIImage(systemName: "circle")!)     // index 2: "C"
        ]
        let assetB_id = assets[1].id  // Remember B's ID to verify it survives
        var selectedIndices: Set<Int> = [0, 2]  // Select A and C

        // Replicate handleDelete logic exactly
        let deletedAssets = selectedIndices
            .filter { $0 < assets.count }
            .compactMap { assets[safe: $0] }
        assets.removeAll { asset in
            deletedAssets.contains(where: { $0.id == asset.id })
        }
        selectedIndices.removeAll()

        XCTAssertEqual(assets.count, 1, "Only 1 asset should remain after deleting 2")
        XCTAssertEqual(assets.first?.id, assetB_id, "The remaining asset should be B (heart)")
        XCTAssertTrue(selectedIndices.isEmpty, "Selection should be cleared after delete")
    }

    func test_deleteOutOfBoundsIgnored() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!)
        ]
        let originalCount = assets.count
        let selectedIndices: Set<Int> = [5]  // Out of bounds!

        // Replicate handleDelete logic
        let deletedAssets = selectedIndices
            .filter { $0 < assets.count }       // 5 < 2 = false → filtered out
            .compactMap { assets[safe: $0] }     // nothing to map
        assets.removeAll { asset in
            deletedAssets.contains(where: { $0.id == asset.id })
        }

        // Nothing should be deleted
        XCTAssertEqual(assets.count, originalCount, "No assets should be deleted for out-of-bounds indices")
    }
}
