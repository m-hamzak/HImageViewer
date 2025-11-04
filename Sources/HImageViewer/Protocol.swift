//
//  Protocol.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 24/04/2025.
//

public protocol HImageViewerControlDelegate: AnyObject {
    func didTapSaveButton( comment: String, photos: [PhotoAsset])
    func didTapCloseButton()
    func didTapEditButton(photo: PhotoAsset)
}
