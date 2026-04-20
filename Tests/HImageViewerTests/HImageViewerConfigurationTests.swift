//
//  HImageViewerConfigurationTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//

import XCTest
import SwiftUI
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

    // MARK: - Theming Tests

    // MARK: - Theming: tintColor

    func test_tintColor_defaultIsNil() {
        XCTAssertNil(HImageViewerConfiguration().tintColor, "Default tintColor must be nil (glass mode)")
    }

    func test_tintColor_nil_activatesGlassMode() {
        let config = HImageViewerConfiguration(tintColor: nil)
        XCTAssertTrue(config.isGlassMode, "nil tintColor must activate glass mode")
    }

    func test_tintColor_customValue_deactivatesGlassMode() {
        let config = HImageViewerConfiguration(tintColor: .red)
        XCTAssertFalse(config.isGlassMode, "Explicit tintColor must deactivate glass mode")
        XCTAssertEqual(config.tintColor, Color.red)
    }

    func test_tintColor_roundTrips() {
        let config = HImageViewerConfiguration(tintColor: .purple)
        XCTAssertEqual(config.tintColor, Color.purple)
    }

    func test_resolvedTintColor_nilReturnsAccentColor() {
        XCTAssertEqual(HImageViewerConfiguration().resolvedTintColor, Color.accentColor,
                       "resolvedTintColor must return .accentColor as fallback when tintColor is nil")
    }

    func test_resolvedTintColor_whenSet_returnsSetColor() {
        let config = HImageViewerConfiguration(tintColor: .green)
        XCTAssertEqual(config.resolvedTintColor, Color.green)
    }

    // MARK: - Theming: placeholderView / errorView

    func test_placeholderView_defaultIsNil() {
        XCTAssertNil(HImageViewerConfiguration().placeholderView, "Default placeholderView must be nil")
    }

    func test_placeholderView_whenSet_isNotNil() {
        let config = HImageViewerConfiguration(placeholderView: AnyView(Text("Loading…")))
        XCTAssertNotNil(config.placeholderView, "placeholderView must be stored when provided")
    }

    func test_errorView_defaultIsNil() {
        XCTAssertNil(HImageViewerConfiguration().errorView, "Default errorView must be nil")
    }

    func test_errorView_whenSet_isNotNil() {
        let config = HImageViewerConfiguration(errorView: AnyView(Text("Failed")))
        XCTAssertNotNil(config.errorView, "errorView must be stored when provided")
    }

    func test_defaultInit_allThemingDefaults() {
        let config = HImageViewerConfiguration()
        XCTAssertNil(config.tintColor)
        XCTAssertTrue(config.isGlassMode)
        XCTAssertNil(config.placeholderView)
        XCTAssertNil(config.errorView)
    }

    // MARK: - isGlassMode additional

    func test_isGlassMode_defaultConfig_isTrue() {
        XCTAssertTrue(HImageViewerConfiguration().isGlassMode)
    }

    func test_isGlassMode_withAnyColor_isFalse() {
        for color: Color in [.red, .green, .orange, .purple, .black, .white] {
            XCTAssertFalse(HImageViewerConfiguration(tintColor: color).isGlassMode,
                           "\(color) tint must deactivate glass mode")
        }
    }

    func test_resolvedTintColor_nilFallsBackToAccentColor() {
        XCTAssertEqual(HImageViewerConfiguration().resolvedTintColor, Color.accentColor)
    }

    func test_resolvedTintColor_customColorPreserved() {
        let config = HImageViewerConfiguration(tintColor: .orange)
        XCTAssertEqual(config.resolvedTintColor, Color.orange)
    }

    func test_allNonDefaultValues_storeProperly() {
        let delegate    = MockDelegate()
        let uploadState = HImageViewerUploadState(progress: 0.5)
        let config = HImageViewerConfiguration(
            initialComment: "Comment",
            delegate: delegate,
            showCommentBox: false,
            showSaveButton: false,
            showEditButton: false,
            title: "My Title",
            uploadState: uploadState,
            tintColor: .orange,
            placeholderView: AnyView(Text("Loading")),
            errorView: AnyView(Text("Error"))
        )
        XCTAssertEqual(config.initialComment, "Comment")
        XCTAssertNotNil(config.delegate)
        XCTAssertFalse(config.showCommentBox)
        XCTAssertFalse(config.showSaveButton)
        XCTAssertFalse(config.showEditButton)
        XCTAssertEqual(config.title, "My Title")
        XCTAssertNotNil(config.uploadState)
        XCTAssertEqual(config.tintColor, Color.orange)
        XCTAssertNotNil(config.placeholderView)
        XCTAssertNotNil(config.errorView)
        XCTAssertFalse(config.isGlassMode)
    }
}
