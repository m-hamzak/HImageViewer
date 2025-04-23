//
//  MultiPhotoGrid.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//


import SwiftUI
import Photos

public struct MultiPhotoGrid: View {
    let assets: [PhotoAsset]
    let selectedIndices: Set<Int>
    let selectionMode: Bool
    let onSelectToggle: (Int) -> Void
//    let onAddMore: () -> Void

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
            ForEach(Array(assets.enumerated()), id: \.1.id) { index, photo in
                ZStack(alignment: .topTrailing) {
                    PhotoView(photo: photo)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)

                    if selectionMode {
                        Button(action: {
                            onSelectToggle(index)
                        }) {
                            Image(systemName: selectedIndices.contains(index) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(selectedIndices.contains(index) ? .blue : .gray)
                                .padding(6)
                        }
                    }
                }
            }

//            // Add More
//            Button(action: onAddMore) {
//                VStack {
//                    Image(systemName: "plus.circle")
//                        .font(.largeTitle)
//                    Text("Add More")
//                        .font(.subheadline)
//                }
//                .frame(width: 100, height: 100)
//                .background(Color.gray.opacity(0.1))
//                .cornerRadius(10)
//            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

