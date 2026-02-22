//
//  HImageViewerConfigurationTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//

import XCTest
@testable import HImageViewer

@MainActor
final class HImageViewerConfigurationTests: XCTestCase {

    // MARK: - Default Value Tests

    func test_defaultInit_allDefaults() {
        let config = HImageViewerConfiguration()

        // Optional properties should be nil (no pre-configured data)
        XCTAssertNil(config.initialComment, "Default initialComment should be nil")
        XCTAssertNil(config.delegate, "Default delegate should be nil")
        XCTAssertNil(config.title, "Default title should be nil")
        XCTAssertNil(config.uploadState, "Default uploadState should be nil")

        // Bool properties should be true (show everything by default)
        XCTAssertTrue(config.showCommentBox, "Default showCommentBox should be true")
        XCTAssertTrue(config.showSaveButton, "Default showSaveButton should be true")
        XCTAssertTrue(config.showEditButton, "Default showEditButton should be true")
    }

    func test_showCommentBox_defaultTrue() {
        XCTAssertTrue(HImageViewerConfiguration().showCommentBox)
    }

    func test_showSaveButton_defaultTrue() {
        XCTAssertTrue(HImageViewerConfiguration().showSaveButton)
    }

    func test_showEditButton_defaultTrue() {
        XCTAssertTrue(HImageViewerConfiguration().showEditButton)
    }

    // MARK: - Custom Value Tests

    func test_customInit_setsAllProperties() {
        let delegate = MockDelegate()
        let uploadState = HImageViewerUploadState(progress: 0.5)

        let config = HImageViewerConfiguration(
            initialComment: "Hello",
            delegate: delegate,
            showCommentBox: false,       // opposite of default
            showSaveButton: false,       // opposite of default
            showEditButton: false,       // opposite of default
            title: "My Title",
            uploadState: uploadState
        )

        XCTAssertEqual(config.initialComment, "Hello")
        XCTAssertNotNil(config.delegate, "Delegate should be stored")
        XCTAssertFalse(config.showCommentBox, "Custom false should override default true")
        XCTAssertFalse(config.showSaveButton, "Custom false should override default true")
        XCTAssertFalse(config.showEditButton, "Custom false should override default true")
        XCTAssertEqual(config.title, "My Title")
        XCTAssertNotNil(config.uploadState, "Upload state should be stored")
    }

    // MARK: - Individual Property Tests

    func test_initialComment_setToNonNil() {
        let config = HImageViewerConfiguration(initialComment: "Pre-filled comment")
        XCTAssertEqual(config.initialComment, "Pre-filled comment")
    }

    func test_title_setToNonNil() {
        let config = HImageViewerConfiguration(title: "Service Photos")
        XCTAssertEqual(config.title, "Service Photos")
    }

    func test_uploadState_setToNonNil() {
        let state = HImageViewerUploadState(progress: 0.3)
        let config = HImageViewerConfiguration(uploadState: state)
        XCTAssertNotNil(config.uploadState)
        XCTAssertEqual(config.uploadState?.progress, 0.3, "Upload state should preserve its progress value")
    }

    func test_delegate_setToNonNil() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        XCTAssertNotNil(config.delegate, "Delegate should be stored in configuration")
    }
}
