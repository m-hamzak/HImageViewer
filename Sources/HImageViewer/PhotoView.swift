//
//  PhotoView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos

public struct PhotoView: View {

    // MARK: - Properties

    @State private var didFailToLoad: Bool = false
    @ObservedObject var photo: PhotoAsset
    let isSinglePhotoMode: Bool

    // MARK: - Theming

    /// Accent color applied to the loading spinner. Defaults to `.blue`.
    var tintColor: Color = .blue
    /// Custom view shown while the photo loads. When `nil`, a gray background + spinner is shown.
    var placeholderView: AnyView? = nil
    /// Custom view shown when the photo fails to load. When `nil`, a red background + warning icon is shown.
    var errorView: AnyView? = nil

    // MARK: - Body

    public var body: some View {
        VStack {
            if isSinglePhotoMode {
                Spacer()
            }
            if let image = photo.image {
                if isSinglePhotoMode {
                    ZoomableImageView(image: image)
                        .cornerRadius(12)
                        .id(photo.id)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(12)
                }
            } else if didFailToLoad {
                if let errorView {
                    errorView
                } else {
                    defaultErrorView
                }
            } else {
                if let placeholderView {
                    placeholderView
                } else {
                    defaultPlaceholderView
                }
            }
            if isSinglePhotoMode {
                Spacer()
            }
        }
        .onAppear {
            guard photo.image == nil, !didFailToLoad else { return }

            let completion: (UIImage?) -> Void = { img in
                if let img = img {
                    self.photo.image = img
                } else {
                    self.didFailToLoad = true
                }
            }

            if isSinglePhotoMode {
                photo.loadFullImage(completion: completion)
            } else {
                photo.loadThumbnail(targetSize: CGSize(width: 150, height: 150), completion: completion)
            }
        }
        .onDisappear {
            photo.cancelPendingLoad()
        }
    }

    // MARK: - Default state views

    private var defaultPlaceholderView: some View {
        Color.gray.opacity(0.1)
            .overlay(
                ProgressView()
                    .tint(tintColor)
            )
    }

    private var defaultErrorView: some View {
        Color.red.opacity(0.2)
            .overlay(
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.largeTitle)
            )
    }
}
