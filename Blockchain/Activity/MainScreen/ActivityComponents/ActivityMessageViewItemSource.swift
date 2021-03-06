//
//  ActivityMessageViewItemSource.swift
//  Blockchain
//
//  Created by Alex McGregor on 8/11/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import LinkPresentation

class ImageActivityItemSource: NSObject, UIActivityItemSource {
    
    private typealias LocalizationId = LocalizationConstants.Activity.Message
    
    let image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let imageProvider = NSItemProvider(object: image)
        
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        metadata.title = LocalizationId.name
        return metadata
    }
}
