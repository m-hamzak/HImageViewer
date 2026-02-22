//
//  MockDelegate.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//

import XCTest
@testable import HImageViewer

// MARK: - MockDelegate

/// Records every delegate call for test verification.
@MainActor
final class MockDelegate: @preconcurrency HImageViewerControlDelegate {

    // MARK: - Save Button Tracking

    /// True if didTapSaveButton was called at least once
    var didTapSaveCalled = false

    /// The comment string from the most recent didTapSaveButton call
    var lastSaveComment: String?

    /// The photos array from the most recent didTapSaveButton call
    var lastSavePhotos: [PhotoAsset]?

    // MARK: - Close Button Tracking

    /// True if didTapCloseButton was called at least once
    var didTapCloseCalled = false

    // MARK: - Edit Button Tracking

    /// True if didTapEditButton was called at least once
    var didTapEditCalled = false

    /// The photo from the most recent didTapEditButton call
    var lastEditPhoto: PhotoAsset?

    // MARK: - Protocol Implementation

    func didTapSaveButton(comment: String, photos: [PhotoAsset]) {
        didTapSaveCalled = true
        lastSaveComment = comment
        lastSavePhotos = photos
    }

    func didTapCloseButton() {
        didTapCloseCalled = true
    }

    func didTapEditButton(photo: PhotoAsset) {
        didTapEditCalled = true
        lastEditPhoto = photo
    }

    // MARK: - Helper Methods

    /// Resets all tracking properties to their initial state.
    func reset() {
        didTapSaveCalled = false
        lastSaveComment = nil
        lastSavePhotos = nil
        didTapCloseCalled = false
        didTapEditCalled = false
        lastEditPhoto = nil
    }
}

// MARK: - MinimalDelegate

/// Uses only default protocol implementations — proves selective adoption works.
/// If this file compiles, it proves default implementations exist.
class MinimalDelegate: HImageViewerControlDelegate {}
