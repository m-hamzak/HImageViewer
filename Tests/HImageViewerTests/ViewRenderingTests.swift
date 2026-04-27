//
//  ViewRenderingTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//
//  Smoke tests — render views and verify they don't crash.
//
//  IMPORTANT: Requires simulator. Run with xcodebuild test, NOT swift test.
//

import XCTest
import SwiftUI
@testable import HImageViewer

@MainActor
final class ViewRenderingTests: XCTestCase {

    // MARK: - Helper

    /// Renders a SwiftUI view to a UIImage for smoke testing.
    func renderView<V: View>(_ view: V, size: CGSize = CGSize(width: 375, height: 667)) -> UIImage {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    // MARK: - Component Smoke Tests

    func test_progressRingOverlayView_renders() {
        let view = ProgressRingOverlayView(progress: 0.5, title: "Uploading")
        let image = renderView(view, size: CGSize(width: 100, height: 120))
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func test_photoView_withImage_renders() {
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        let view = PhotoView(photo: photo, isSinglePhotoMode: true)
        let image = renderView(view)
        XCTAssertGreaterThan(image.size.width, 0, "PhotoView should render successfully")
    }

    func test_multiPhotoGrid_renders() {
        let mediaItems: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .photo(PhotoAsset(image: UIImage(systemName: "heart")!)),
            .photo(PhotoAsset(image: UIImage(systemName: "circle")!))
        ]
        let view = MultiPhotoGrid(
            mediaItems: mediaItems,
            selectedIndices: [],
            selectionMode: false,
            onSelectToggle: { _ in }
        )
        let image = renderView(view)
        XCTAssertGreaterThan(image.size.width, 0, "MultiPhotoGrid should render successfully")
    }

    func test_multiPhotoGrid_withVideoItem_renders() {
        let mediaItems: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .video(URL(string: "https://example.com/clip.mp4")!)
        ]
        let view = MultiPhotoGrid(
            mediaItems: mediaItems,
            selectedIndices: [],
            selectionMode: false,
            onSelectToggle: { _ in }
        )
        let image = renderView(view)
        XCTAssertGreaterThan(image.size.width, 0, "MultiPhotoGrid with video placeholder should render")
    }

    // MARK: - Full Viewer Smoke Tests

    func test_hImageViewer_singleItem_renders() {
        let items: [MediaAsset] = [.photo(PhotoAsset(image: UIImage(systemName: "star")!))]
        let view = HImageViewer(mediaAssets: .constant(items))
        let image = renderView(view)
        XCTAssertGreaterThan(image.size.width, 0, "Single-item viewer should render successfully")
    }

    func test_hImageViewer_multipleItems_renders() {
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .photo(PhotoAsset(image: UIImage(systemName: "heart")!)),
            .photo(PhotoAsset(image: UIImage(systemName: "circle")!))
        ]
        let view = HImageViewer(mediaAssets: .constant(items))
        let image = renderView(view)
        XCTAssertGreaterThan(image.size.width, 0, "Multi-item viewer should render successfully")
    }

    func test_hImageViewer_mixedMedia_renders() {
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .video(URL(string: "https://example.com/test.mp4")!)
        ]
        let view = HImageViewer(mediaAssets: .constant(items))
        let image = renderView(view)
        XCTAssertGreaterThan(image.size.width, 0, "Mixed media viewer must render without crashing")
    }

    func test_hImageViewer_withTintColor_renders() {
        let items: [MediaAsset] = [.photo(PhotoAsset(image: UIImage(systemName: "star")!))]
        let config = HImageViewerConfiguration(tintColor: .purple)
        let view = HImageViewer(mediaAssets: .constant(items), configuration: config)
        let image = renderView(view)
        XCTAssertGreaterThan(image.size.width, 0, "Tinted viewer must render")
    }

    func test_hImageViewer_emptyAssets_renders() {
        let view = HImageViewer(mediaAssets: .constant([]))
        let image = renderView(view)
        XCTAssertGreaterThan(image.size.width, 0, "Viewer with empty assets must not crash")
    }

    func test_hImageViewer_initialIndex_renders() {
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .photo(PhotoAsset(image: UIImage(systemName: "heart")!))
        ]
        let view = HImageViewer(mediaAssets: .constant(items), initialIndex: 1)
        let image = renderView(view)
        XCTAssertGreaterThan(image.size.width, 0, "Viewer opened at non-zero index must render")
    }

    func test_progressRingOverlayView_atZeroPercent_renders() {
        let view = ProgressRingOverlayView(progress: 0.0, title: nil)
        let image = renderView(view, size: CGSize(width: 100, height: 100))
        XCTAssertGreaterThan(image.size.width, 0)
    }

    func test_progressRingOverlayView_atComplete_renders() {
        let view = ProgressRingOverlayView(progress: 1.0, title: "Done")
        let image = renderView(view, size: CGSize(width: 100, height: 100))
        XCTAssertGreaterThan(image.size.width, 0)
    }

    func test_topBar_inSelectionMode_renders() {
        let config = TopBarConfig(
            showEditButton: false, showSelectButton: false,
            selectionMode: true, pageCounterText: nil,
            onDismiss: {}, onCancelSelection: {}, onSelectToggle: {}, onEdit: {}
        )
        let image = renderView(TopBar(config: config), size: CGSize(width: 375, height: 56))
        XCTAssertGreaterThan(image.size.width, 0)
    }
}
