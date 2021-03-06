//
//  TetherToken.swift
//  ERC20Kit
//
//  Created by Paulo on 01/07/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import BigInt
import EthereumKit
import PlatformKit

public struct TetherToken: ERC20Token {
    public static let assetType: CryptoCurrency = .tether
    public static let contractAddress: EthereumContractAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"

    //swiftlint:disable:next force_try
    public static var smallestSpendableValue: ERC20TokenValue<TetherToken> = try! ERC20TokenValue<TetherToken>(
        crypto: CryptoValue.createFromMajorValue(string: "0.01", assetType: assetType, locale: Locale.Posix)!
    )
}
