//
//  HImageViewerConfiguration.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 08/07/2025.
//

public struct HImageViewerConfiguration {
    public let initialComment: String?
    public let delegate: ImageViewerDelegate?
    public let showCommentBox: Bool
    public let showSaveButton: Bool
    public let title: String?
    
    public init(
        initialComment: String? = nil,
        delegate: ImageViewerDelegate? = nil,
        showCommentBox: Bool = true,
        showSaveButton: Bool = true,
        title: String? = nil
    ) {
        self.initialComment = initialComment
        self.delegate = delegate
        self.showCommentBox = showCommentBox
        self.showSaveButton = showSaveButton
        self.title = title
    }
}
//public struct HImageViewerConfiguration {
//    public var comment: String? = nil
//    public var showCommentBox: Bool = true
//    public var showSaveButton: Bool = true
//    public var title: String? = nil
//    public weak var delegate: ImageViewerDelegate? = nil
//
//    public init() {}
//}
//
//extension HImageViewerConfiguration {
//    public mutating func withComment(_ comment: String) -> Self {
//        self.comment = comment
//        return self
//    }
//
//    public mutating func withTitle(_ title: String) -> Self {
//        self.title = title
//        return self
//    }
//
//    public mutating func hideSaveButton() -> Self {
//        self.showSaveButton = false
//        return self
//    }
//
//    public mutating func hideCommentBox() -> Self {
//        self.showCommentBox = false
//        return self
//    }
//}

