//
//  Protocol.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 24/04/2025.
//

public protocol ImageViewerDelegate: AnyObject {
    func didAddPhotos(_ photos: [PhotoAsset])
    func didSaveComment(_ comment: String)
    func didDeletePhotos(_ photos: [PhotoAsset])
}
