//
//  PhotoAsset.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import Photos

struct PhotoAsset: Identifiable, Equatable {
    let id = UUID()
    let asset: PHAsset
}
