//
//  ThumbnailImageView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos

struct ThumbnailImageView: View {
    let asset: PHAsset
    @State private var image: UIImage?

    private let manager = PHCachingImageManager()

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .onAppear {
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            options.resizeMode = .fast

            manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100),
                                 contentMode: .aspectFill, options: options) { image, _ in
                self.image = image
            }
        }
    }
}
