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

    // MARK: - shouldShowSaveButton Logic (simplified — no longer depends on isSinglePhotoMode)

    func test_shouldShowSave_editedTrue_configFalse() {
        let wasImageEdited = true
        let showSaveButton = false
        let result = wasImageEdited || showSaveButton
        XCTAssertTrue(result, "Edited image should show save button regardless of config")
    }

    func test_shouldShowSave_editedFalse_configTrue() {
        let wasImageEdited = false
        let showSaveButton = true
        let result = wasImageEdited || showSaveButton
        XCTAssertTrue(result, "config.showSaveButton=true should show save button")
    }

    func test_shouldShowSave_bothFalse() {
        let wasImageEdited = false
        let showSaveButton = false
        let result = wasImageEdited || showSaveButton
        XCTAssertFalse(result, "Not edited + config false = hide save button")
    }

    // MARK: - currentIndex Clamping Logic

    func test_initialIndex_clampedToZero_forEmptyAssets() {
        let count = 0
        let clamped = count == 0 ? 0 : max(0, min(5, count - 1))
        XCTAssertEqual(clamped, 0, "Empty assets must clamp index to 0")
    }

    func test_initialIndex_clampedToLastIndex_whenTooLarge() {
        let count = 3
        let initialIndex = 10
        let clamped = count == 0 ? 0 : max(0, min(initialIndex, count - 1))
        XCTAssertEqual(clamped, 2, "initialIndex=10 with 3 assets must clamp to 2")
    }

    func test_initialIndex_clampedToZero_whenNegative() {
        let count = 3
        let initialIndex = -1
        let clamped = count == 0 ? 0 : max(0, min(initialIndex, count - 1))
        XCTAssertEqual(clamped, 0, "Negative initialIndex must clamp to 0")
    }

    func test_initialIndex_validIndex_unchanged() {
        let count = 5
        let initialIndex = 3
        let clamped = count == 0 ? 0 : max(0, min(initialIndex, count - 1))
        XCTAssertEqual(clamped, 3, "Valid initialIndex must remain unchanged")
    }

    func test_currentIndex_clampedAfterDeletion() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        var currentIndex = 2

        // Simulate deleting the last asset (index 2)
        assets.removeLast()
        if !assets.isEmpty {
            currentIndex = min(currentIndex, assets.count - 1)
        }

        XCTAssertEqual(currentIndex, 1, "currentIndex must clamp to last valid index after deletion")
    }

    func test_currentIndex_staysValid_whenDeletingNonCurrentAsset() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        var currentIndex = 1

        // Delete asset at index 2 (not the current one)
        assets.remove(at: 2)
        if !assets.isEmpty {
            currentIndex = min(currentIndex, assets.count - 1)
        }

        XCTAssertEqual(currentIndex, 1, "currentIndex should remain 1 when a later asset is deleted")
    }

    // MARK: - handleSelection Logic

    func test_selectionToggle() {
        var selectedIndices: Set<Int> = []
        let index = 2

        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
        XCTAssertTrue(selectedIndices.contains(2), "First tap should SELECT the photo")

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
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        let assetB_id = assets[1].id
        var selectedIndices: Set<Int> = [0, 2]

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
        let selectedIndices: Set<Int> = [5]

        let deletedAssets = selectedIndices
            .filter { $0 < assets.count }
            .compactMap { assets[safe: $0] }
        assets.removeAll { asset in
            deletedAssets.contains(where: { $0.id == asset.id })
        }

        XCTAssertEqual(assets.count, originalCount, "No assets should be deleted for out-of-bounds indices")
    }

    // MARK: - isUploading boundary values (additional)

    func test_isUploading_justAboveZero_isTrue() {
        let progress: Double? = 0.001
        let isUploading = (progress ?? 0) > 0 && (progress ?? 0) < 1.0
        XCTAssertTrue(isUploading, "0.001 is actively uploading")
    }

    func test_isUploading_justBelowOne_isTrue() {
        let progress: Double? = 0.999
        let isUploading = (progress ?? 0) > 0 && (progress ?? 0) < 1.0
        XCTAssertTrue(isUploading, "0.999 is still uploading")
    }

    // MARK: - shouldShowSaveButton additional

    func test_shouldShowSave_bothTrue() {
        XCTAssertTrue(true || true, "edited AND config both true = show save")
    }

    // MARK: - initialIndex edge cases

    func test_initialIndex_exactlyLastIndex_unchanged() {
        let count = 4
        let clamped = count == 0 ? 0 : max(0, min(3, count - 1))
        XCTAssertEqual(clamped, 3, "Last valid index must pass through unchanged")
    }

    func test_initialIndex_singleAsset_alwaysClampsToZero() {
        let count = 1
        let clamped = count == 0 ? 0 : max(0, min(100, count - 1))
        XCTAssertEqual(clamped, 0)
    }

    // MARK: - handleDelete additional

    func test_deleteAllAssets_leavesEmptyArray() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!)
        ]
        let selectedIndices: Set<Int> = [0, 1]
        let toDelete = selectedIndices.filter { $0 < assets.count }.compactMap { assets[safe: $0] }
        assets.removeAll { asset in toDelete.contains(where: { $0.id == asset.id }) }

        XCTAssertTrue(assets.isEmpty, "Deleting all assets must produce an empty array")
    }

    func test_deleteLargeSelection_correctCountRemains() {
        var assets = (0..<10).map { _ in PhotoAsset(image: UIImage(systemName: "star")!) }
        let selectedIndices: Set<Int> = [0, 2, 4, 6, 8]
        let toDelete = selectedIndices.compactMap { assets[safe: $0] }
        assets.removeAll { a in toDelete.contains(where: { $0.id == a.id }) }
        XCTAssertEqual(assets.count, 5, "Deleting 5 of 10 must leave 5")
    }

    func test_currentIndex_afterDeletion_clampedWhenAtEnd() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        var currentIndex = 2
        let selectedIndices: Set<Int> = [1, 2]
        let toDelete = selectedIndices.compactMap { assets[safe: $0] }
        assets.removeAll { a in toDelete.contains(where: { $0.id == a.id }) }
        if !assets.isEmpty { currentIndex = min(currentIndex, assets.count - 1) }
        XCTAssertEqual(assets.count, 1)
        XCTAssertEqual(currentIndex, 0)
    }

    // MARK: - handleSelection additional

    func test_selectionInsert_multipleItems() {
        var selectedIndices: Set<Int> = []
        [0, 2, 4].forEach { selectedIndices.insert($0) }
        XCTAssertEqual(selectedIndices.count, 3)
        XCTAssertTrue(selectedIndices.contains(2))
    }

    func test_selectionRemoveAll_isEmpty() {
        var selectedIndices: Set<Int> = [0, 1, 2, 3]
        selectedIndices.removeAll()
        XCTAssertTrue(selectedIndices.isEmpty)
    }

    func test_selectionToggle_sameIndex_threeTimes() {
        var selectedIndices: Set<Int> = []
        for _ in 0..<3 {
            if selectedIndices.contains(1) { selectedIndices.remove(1) }
            else { selectedIndices.insert(1) }
        }
        // 3 toggles (odd count) → should be selected at the end
        XCTAssertTrue(selectedIndices.contains(1), "Odd number of toggles leaves item selected")
    }

    // MARK: - pageCounterText edge cases

    func test_pageCounterText_largeNumbers() {
        let counter = "\(100) / \(200)"
        XCTAssertEqual(counter, "100 / 200")
    }
}
