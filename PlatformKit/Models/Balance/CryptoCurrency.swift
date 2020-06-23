//
//  CryptoCurrency.swift
//  PlatformKit
//
//  Created by AlexM on 12/5/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Localization

/// This is used to distinguish between different types of digital assets.
/// `PlatformKit` should be almost entirely `CryptoCurrency` agnostic however.
/// It's possible that we may move this along with the other `Balance` related
/// models to a separate framework called `BalanceKit`.
/// This should be used a replacement for `AssetType` which is currently defined
/// in the app target.
public enum CryptoCurrency: String, Codable, CaseIterable {
    case bitcoin = "BTC"
    case ethereum = "ETH"
    case bitcoinCash = "BCH"
    case stellar = "XLM"
    case pax = "PAX"
    case algorand = "ALGO"

    /// Initialize with currency code: `BTC`, `ETH`, `BCH`, `XLM`, `PAX`, `ALGO`
    public init?(code: String) {
        self.init(rawValue: code.uppercased())
    }
}

extension CryptoCurrency {

    public var hasNonCustodialSupport: Bool {
        switch self {
        case .algorand:
            return false
        case .bitcoin,
             .bitcoinCash,
             .ethereum,
             .pax,
             .stellar:
            return true
        }
    }

    public var name: String {
        switch self {
        case .algorand:
            return "Algorand"
        case .bitcoin:
            return "Bitcoin"
        case .bitcoinCash:
            return "Bitcoin Cash"
        case .ethereum:
            return "Ether"
        case .pax:
            return "USD \(LocalizationConstants.digital)"
        case .stellar:
            return "Stellar"
        }
    }
    
    public var code: String {
        rawValue
    }

    public var displayCode: String {
        switch self {
        case .algorand, .bitcoin, .bitcoinCash, .ethereum, .stellar:
            return code
        case .pax:
            return "USD-D"
        }
    }
    
    public var maxDecimalPlaces: Int {
        switch self {
        case .algorand:
            return 6
        case .bitcoin:
            return 8
        case .bitcoinCash:
            return 8
        case .ethereum:
            return 18
        case .pax:
            return 18
        case .stellar:
            return 7
        }
    }
    
    public var maxDisplayableDecimalPlaces: Int {
        switch self {
        case .algorand:
            return 2
        case .bitcoin:
            return 8
        case .bitcoinCash:
            return 8
        case .ethereum:
            return 8
        case .pax:
            return 8
        case .stellar:
            return 7
        }
    }
}
