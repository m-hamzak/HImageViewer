//
//  PhotoView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos

public struct PhotoView: View {
    @State private var thumbnail: UIImage?
      let photo: PhotoAsset

      public var body: some View {
          Group {
              if let thumbnail {
                  Image(uiImage: thumbnail)
                      .resizable()
                      .scaledToFill()
              } else {
                  Color.gray.opacity(0.2)
                      .overlay(
                          ProgressView()
                      )
              }
          }
          .onAppear {
              if thumbnail == nil {
                  photo.loadThumbnail(targetSize: CGSize(width: 150, height: 150)) { img in
                      self.thumbnail = img
                  }
              }
          }
      }
}
