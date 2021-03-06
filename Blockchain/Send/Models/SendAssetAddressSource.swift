//
//  SendAssetAddressSource.swift
//  Blockchain
//
//  Created by Daniel Huri on 23/07/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

/// The source of the address on the send screen
enum SendAssetAddressSource {
    
    /// Exchange address (Exchange button)
    case exchange
    
    /// Standard address (keyboard source)
    case standard
}
