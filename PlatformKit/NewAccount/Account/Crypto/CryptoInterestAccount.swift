//
//  CryptoInterestAccount.swift
//  PlatformKit
//
//  Created by Paulo on 07/08/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import DIKit
import Localization
import RxSwift
import ToolKit

public class CryptoInterestAccount: CryptoAccount {
    private typealias LocalizedString = LocalizationConstants.Account

    public lazy var id: String = "CryptoInterestAccount." + asset.code
    public let label: String
    public let asset: CryptoCurrency
    public let isDefault: Bool = false

    public var balance: Single<MoneyValue> {
        balanceFetching.balanceMoney
    }

    public var actions: AvailableActions {
        []
    }

    private let balanceFetching: CustodialAccountBalanceFetching
    private let exchangeService: PairExchangeServiceAPI

    public init(asset: CryptoCurrency,
                balanceProviding: BalanceProviding = resolve(),
                exchangeProviding: ExchangeProviding = resolve()) {
        self.label = String(format: LocalizedString.myInterestAccount, asset.name)
        self.asset = asset
        self.exchangeService = exchangeProviding[asset]
        self.balanceFetching = balanceProviding[asset.currency].savings
    }

    public func fiatBalance(fiatCurrency: FiatCurrency) -> Single<MoneyValue> {
        Single
            .zip(
                exchangeService.fiatPrice.take(1).asSingle(),
                balance
            ) { (exchangeRate: $0, balance: $1) }
            .map { try MoneyValuePair(base: $0.balance, exchangeRate: $0.exchangeRate.moneyValue) }
            .map(\.quote)
    }
}