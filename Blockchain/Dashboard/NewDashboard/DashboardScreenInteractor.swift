//
//  DashboardScreenInteractor.swift
//  Blockchain
//
//  Created by Daniel Huri on 22/10/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit
import PlatformUIKit
import RxSwift
import RxRelay
import BuySellKit
import DIKit

final class DashboardScreenInteractor {
    
    // MARK: - Services
    
    let balanceProvider: BalanceProviding
    let historicalProvider: HistoricalFiatPriceProviding
    let balanceChangeProvider: BalanceChangeProviding
    let reactiveWallet: ReactiveWalletAPI
    let lockboxRepository: LockboxRepositoryAPI
    let userPropertyInteractor: AnalyticsUserPropertyInteractor
    
    let historicalBalanceInteractors: [HistoricalBalanceCellInteractor]
    let fiatBalancesInteractor: DashboardFiatBalancesInteractor
    let enabledCurrenciesService: EnabledCurrenciesServiceAPI
    
    var enabledCryptoCurrencies: [CryptoCurrency] {
        enabledCurrenciesService.allEnabledCryptoCurrencies
    }
    
    // MARK: - Private Accessors
    
    private let disposeBag = DisposeBag()
    
    init(balanceProvider: BalanceProviding = DataProvider.default.balance,
         historicalProvider: HistoricalFiatPriceProviding = DataProvider.default.historicalPrices,
         balanceChangeProvider: BalanceChangeProviding = DataProvider.default.balanceChange,
         paymentMethodsService: PaymentMethodsServiceAPI = DataProvider.default.buySell.paymentMethods,
         enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve(),
         lockboxRepository: LockboxRepositoryAPI = LockboxRepository(),
         featureFetcher: FeatureFetching = AppFeatureConfigurator.shared,
         reactiveWallet: ReactiveWalletAPI = WalletManager.shared.reactiveWallet,
         userPropertyInteractor: AnalyticsUserPropertyInteractor = AnalyticsUserPropertyInteractor()) {
        self.historicalProvider = historicalProvider
        self.balanceProvider = balanceProvider
        self.balanceChangeProvider = balanceChangeProvider
        self.lockboxRepository = lockboxRepository
        self.reactiveWallet = reactiveWallet
        self.enabledCurrenciesService = enabledCurrenciesService
        self.userPropertyInteractor = userPropertyInteractor
        historicalBalanceInteractors = enabledCurrenciesService.allEnabledCryptoCurrencies.map {
            HistoricalBalanceCellInteractor(
                cryptoCurrency: $0,
                historicalFiatPriceService: historicalProvider[$0],
                assetBalanceFetcher: balanceProvider[$0.currency]
            )
        }
        fiatBalancesInteractor = DashboardFiatBalancesInteractor(
            balanceProvider: balanceProvider,
            featureFetcher: featureFetcher,
            paymentMethodsService: paymentMethodsService,
            enabledCurrenciesService: enabledCurrenciesService
        )
    }
    
    func refresh() {
        reactiveWallet.waitUntilInitialized
            .bind { [weak self] _ in
                guard let self = self else { return }
                
                /// Refresh dashboard interaction layer
                self.historicalProvider.refresh(window: .day(.oneHour))
                self.balanceProvider.refresh()
                
                /// Record user properties once wallet is initialized
                self.userPropertyInteractor.record()
            }
            .disposed(by: disposeBag)
    }
}
