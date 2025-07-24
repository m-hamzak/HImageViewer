//
//  PhotoView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos

public struct PhotoView: View {
    
    @State private var didFailToLoad: Bool = false
    @ObservedObject var photo: PhotoAsset
    let isSinglePhotoMode: Bool
    
    public var body: some View {
        VStack {
            if isSinglePhotoMode {
                Spacer()
            }
            if let image = photo.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: isSinglePhotoMode ? .fit : .fill)
                    .cornerRadius(12) 
            } else if didFailToLoad {
                Color.red.opacity(0.2)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.largeTitle)
                    )
            } else {
                Color.gray.opacity(0.1)
                    .overlay(
                        ProgressView()
                    )
            }
            if isSinglePhotoMode {
                Spacer()
            }
        }
        .onAppear {
            guard photo.image == nil && !didFailToLoad else { return }
            
            if let url = photo.imageURL {
                // Load image from remote URL
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url), let loadedImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.photo.image = loadedImage
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.didFailToLoad = true
                        }
                    }
                }
                return
            }
            
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
    }
}
