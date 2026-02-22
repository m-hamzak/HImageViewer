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
        // Step 1: Wrap SwiftUI view in UIKit container
        let controller = UIHostingController(rootView: view)

        // Step 2: Give it a frame (simulates a screen)
        controller.view.frame = CGRect(origin: .zero, size: size)

        // Step 3: Trigger SwiftUI layout
        controller.view.layoutIfNeeded()

        // Step 4-5: Render to image
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    // MARK: - Component Smoke Tests

    func test_progressRingOverlayView_renders() {
        let view = ProgressRingOverlayView(progress: 0.5, title: "Uploading")
        let image = renderView(view, size: CGSize(width: 100, height: 120))

        XCTAssertGreaterThan(image.size.width, 0, "Rendered image should have non-zero width")
        XCTAssertGreaterThan(image.size.height, 0, "Rendered image should have non-zero height")
    }

    func test_photoView_withImage_renders() {
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        let view = PhotoView(photo: photo, isSinglePhotoMode: true)
        let image = renderView(view)

        XCTAssertGreaterThan(image.size.width, 0, "PhotoView should render successfully")
    }

    func test_multiPhotoGrid_renders() {
        let assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        let view = MultiPhotoGrid(
            assets: assets,
            selectedIndices: [],
            selectionMode: false,
            onSelectToggle: { _ in }   // no-op for tests
        )
        let image = renderView(view)

        XCTAssertGreaterThan(image.size.width, 0, "MultiPhotoGrid should render successfully")
    }

    // MARK: - Full Viewer Smoke Tests

    func test_hImageViewer_singleMode_renders() {
        let assets = [PhotoAsset(image: UIImage(systemName: "star")!)]
        let view = HImageViewer(
            assets: .constant(assets),
            selectedVideo: .constant(nil)
        )
        let image = renderView(view)

        XCTAssertGreaterThan(image.size.width, 0, "Single-mode viewer should render successfully")
    }

    func test_hImageViewer_multiMode_renders() {
        let assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        let view = HImageViewer(
            assets: .constant(assets),
            selectedVideo: .constant(nil)
        )
        let image = renderView(view)

        XCTAssertGreaterThan(image.size.width, 0, "Multi-mode viewer should render successfully")
    }
}
