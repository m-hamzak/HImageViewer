//
//  HImageViewerLauncherTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 21/04/2026.
//
//  Verifies HImageViewerLauncher's present and push entry points.
//  Tests run on the main actor so UIKit calls are safe.
//

import XCTest
import SwiftUI
import UIKit
@testable import HImageViewer

@MainActor
final class HImageViewerLauncherTests: XCTestCase {

    // MARK: - Helpers

    private func makeAssets(_ count: Int = 1) -> [PhotoAsset] {
        (0..<count).map { _ in PhotoAsset(image: UIImage(systemName: "star")!) }
    }

    private func makeMediaAssets(_ count: Int = 1) -> [MediaAsset] {
        (0..<count).map { _ in .photo(PhotoAsset(image: UIImage(systemName: "star")!)) }
    }

    /// Returns a `UIViewController` embedded in a `UINavigationController`
    /// and installed in the key window so UIKit presentation works.
    private func makeNavigationStack() -> (nav: UINavigationController, root: UIViewController) {
        let root = UIViewController()
        let nav  = UINavigationController(rootViewController: root)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        return (nav, root)
    }

    /// Returns a standalone `UIViewController` with no navigation controller.
    private func makeStandaloneVC() -> UIViewController {
        let vc = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc
        window.makeKeyAndVisible()
        return vc
    }

    // MARK: - present (photo-only)

    func test_present_photos_presentsHostingController() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.present(from: vc, assets: makeAssets())
        XCTAssertNotNil(vc.presentedViewController,
                        "present must push a hosting controller modally")
    }

    func test_present_photos_presentedVCIsHostingController() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.present(from: vc, assets: makeAssets())
        XCTAssertTrue(vc.presentedViewController is UIHostingController<PhotoViewerContainer>,
                      "Presented controller must be a UIHostingController wrapping PhotoViewerContainer")
    }

    func test_present_photos_usesFullScreenStyle() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.present(from: vc, assets: makeAssets())
        XCTAssertEqual(vc.presentedViewController?.modalPresentationStyle, .fullScreen)
    }

    // MARK: - present (media)

    func test_present_media_presentsHostingController() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.present(from: vc, mediaAssets: makeMediaAssets())
        XCTAssertNotNil(vc.presentedViewController,
                        "present(mediaAssets:) must push a hosting controller modally")
    }

    func test_present_media_usesFullScreenStyle() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.present(from: vc, mediaAssets: makeMediaAssets())
        XCTAssertEqual(vc.presentedViewController?.modalPresentationStyle, .fullScreen)
    }

    // MARK: - push (photo-only)

    func test_push_photos_pushesOntoNavigationStack() {
        let (nav, root) = makeNavigationStack()
        HImageViewerLauncher.push(from: root, assets: makeAssets())
        XCTAssertEqual(nav.viewControllers.count, 2,
                       "push must add the viewer to the navigation stack")
    }

    func test_push_photos_pushedVCIsHostingController() {
        let (nav, root) = makeNavigationStack()
        HImageViewerLauncher.push(from: root, assets: makeAssets())
        XCTAssertTrue(nav.viewControllers.last is UIHostingController<PhotoViewerContainer>,
                      "Pushed controller must be a UIHostingController wrapping PhotoViewerContainer")
    }

    func test_push_photos_noNavigationController_isNoOp() {
        let vc = makeStandaloneVC()
        // Must not crash and must not present anything.
        HImageViewerLauncher.push(from: vc, assets: makeAssets())
        XCTAssertNil(vc.presentedViewController,
                     "push without a navigation controller must be a silent no-op")
    }

    // MARK: - push (media)

    func test_push_media_pushesOntoNavigationStack() {
        let (nav, root) = makeNavigationStack()
        HImageViewerLauncher.push(from: root, mediaAssets: makeMediaAssets())
        XCTAssertEqual(nav.viewControllers.count, 2,
                       "push(mediaAssets:) must add the viewer to the navigation stack")
    }

    func test_push_media_noNavigationController_isNoOp() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.push(from: vc, mediaAssets: makeMediaAssets())
        XCTAssertNil(vc.presentedViewController,
                     "push(mediaAssets:) without a navigation controller must be a silent no-op")
    }

    // MARK: - push vs present produce different presentation styles

    func test_present_isModal_push_isNavigation() {
        let (nav, root) = makeNavigationStack()

        // Present from a different VC so the stack isn't modified.
        let standalone = makeStandaloneVC()
        HImageViewerLauncher.present(from: standalone, assets: makeAssets())
        XCTAssertNotNil(standalone.presentedViewController, "present → modal")

        // Push from the nav-stack VC.
        HImageViewerLauncher.push(from: root, assets: makeAssets())
        XCTAssertEqual(nav.viewControllers.count, 2, "push → navigation stack")
    }
}
