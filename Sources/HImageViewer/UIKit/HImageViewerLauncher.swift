//
//  HImageViewerLauncher.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 22/04/2025.
//

import SwiftUI
import UIKit

public final class ImageViewerLauncher {
    @MainActor public static func present(
        from viewController: UIViewController,
        assets: [PhotoAsset],
        selectedVideo: URL? = nil,
        configuration: HImageViewerConfiguration
    ) {
        let viewer = HImageViewer(
            assets: .constant(assets),
            selectedVideo: .constant(selectedVideo),
            configuration: configuration
        )

        let hostingController = UIHostingController(rootView: viewer)
        hostingController.modalPresentationStyle = .fullScreen
        viewController.present(hostingController, animated: true)
    }
}
