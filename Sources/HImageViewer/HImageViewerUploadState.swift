//
//  HImageViewerUploadState.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 11/07/2025.
//

import Foundation

public class HImageViewerUploadState: ObservableObject {
    @Published public var progress: Double? = nil

    public init(progress: Double? = nil) {
        self.progress = progress
    }
}
