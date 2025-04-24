//
//  PhotoView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos

public struct PhotoView: View {
    @State private var image: UIImage?
    @State private var didFailToLoad: Bool = false
    let photo: PhotoAsset
    let isSinglePhotoMode: Bool

    public var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if didFailToLoad {
                Color.red.opacity(0.2)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.largeTitle)
                    )
            } else {
                Color.gray.opacity(0.2)
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .onAppear {
            guard image == nil && !didFailToLoad else { return }

            let completion: (UIImage?) -> Void = { img in
                if let img = img {
                    self.image = img
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
    }
}
