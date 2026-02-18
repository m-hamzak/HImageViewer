//
//  MultiPhotoGrid.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//


import SwiftUI
import Photos

public struct MultiPhotoGrid: View {

    // MARK: - Properties

    let assets: [PhotoAsset]
    let selectedIndices: Set<Int>
    let selectionMode: Bool
    let onSelectToggle: (Int) -> Void

    let itemSize: CGFloat = 110

    // MARK: - Body

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: itemSize), spacing: 10)], spacing: 10) {
            ForEach(Array(assets.enumerated()), id: \.1.id) { index, photo in
                ZStack(alignment: .topTrailing) {
                    PhotoView(photo: photo, isSinglePhotoMode: false)
                        .frame(width: itemSize, height: itemSize)
                        .cornerRadius(12)

                    if selectionMode {
                        Button(action: {
                            onSelectToggle(index)
                        }) {
                            Image(systemName: selectedIndices.contains(index) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(selectedIndices.contains(index) ? .blue : .gray)
                                .padding(4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

