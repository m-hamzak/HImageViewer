//
//  Protocol.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 24/04/2025.
//

public protocol ImageViewerDelegate: AnyObject {
    func didTapSaveButton( comment: String, photos: [PhotoAsset])
    func didTapCloseButton()
    func didTapEditButton()
}
