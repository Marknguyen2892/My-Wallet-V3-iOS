//
//  CryptoCurrency+Extensions.swift
//  Blockchain
//
//  Created by Maurice A. on 4/13/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit
import PlatformUIKit

extension CryptoCurrency {

    /// The legacy representation of `CryptoCurrency`
    var legacy: LegacyAssetType {
        switch self {
        case .algorand:
            return .algorand
        case .bitcoin:
            return .bitcoin
        case .bitcoinCash:
            return .bitcoinCash
        case .ethereum:
            return .ether
        case .pax:
            return .pax
        case .stellar:
            return .stellar
        }
    }
    
    /// Returns `true` if an asset's addresses can be reused
    var shouldAddressesBeReused: Bool {
        return Set<CryptoCurrency>([.ethereum, .stellar, .pax]).contains(self)
    }
    
    /// Returns `true` for a bitcoin cash asset
    var isBitcoinCash: Bool {
        if case .bitcoinCash = self {
            return true
        } else {
            return false
        }
    }
    
    /// Returns `true` for any ERC20 asset
    var isERC20: Bool {
        switch self {
        case .pax:
            return true
        case .algorand, .bitcoin, .bitcoinCash, .ethereum, .stellar:
            return false
        }
    }

    init(legacyAssetType: LegacyAssetType) {
        switch legacyAssetType {
        case .algorand:
            self = .algorand
        case .bitcoin:
            self = .bitcoin
        case .bitcoinCash:
            self = .bitcoinCash
        case .ether:
            self = .ethereum
        case .stellar:
            self = .stellar
        case .pax:
            self = .pax
        }
    }
}
