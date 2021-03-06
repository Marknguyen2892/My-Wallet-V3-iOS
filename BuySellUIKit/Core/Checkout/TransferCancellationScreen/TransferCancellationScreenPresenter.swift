//
//  TransferCancellationScreenPresenter.swift
//  Blockchain
//
//  Created by AlexM on 2/24/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import Localization
import PlatformKit
import PlatformUIKit
import RxRelay
import RxSwift
import ToolKit

final class TransferCancellationScreenPresenter {
    
    // MARK: - Localization
    
    private typealias AnalyticsEvent = AnalyticsEvents.SimpleBuy
    private typealias AccessibilityIDs = Accessibility.Identifier.SimpleBuy.Cancellation
    private typealias LocalizationIDs = LocalizationConstants.SimpleBuy.TransferDetails.Cancellation
    
    // MARK: - Public Properties
    
    let titleContent: LabelContent
    let descriptionContent: LabelContent
    
    let noButtonViewModel: ButtonViewModel
    let yesButtonViewModel: ButtonViewModel
    
    let dismissalRelay = PublishRelay<Void>()
    
    // MARK: - Private Properties
    
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let uiUtilityProvider: UIUtilityProviderAPI
    private let stateService: StateServiceAPI
    private let interactor: TransferCancellationInteractor
    private let disposeBag = DisposeBag()
    
    init(stateService: StateServiceAPI,
         currency: CryptoCurrency,
         uiUtilityProvider: UIUtilityProviderAPI = UIUtilityProvider.default,
         analyticsRecorder: AnalyticsEventRecorderAPI,
         interactor: TransferCancellationInteractor) {
        self.analyticsRecorder = analyticsRecorder
        self.interactor = interactor
        self.stateService = stateService
        self.uiUtilityProvider = uiUtilityProvider
        
        titleContent = .init(
            text: LocalizationIDs.title,
            font: .main(.semibold, 20.0),
            color: .textFieldText,
            alignment: .center,
            accessibility: .id(AccessibilityIDs.titleLabel)
        )
        descriptionContent = .init(
            text: "\(LocalizationIDs.Description.thisWillRemove) \(currency.name) \(LocalizationIDs.Description.buyOrder)",
            font: .main(.medium, 14.0),
            color: .textFieldText,
            alignment: .center,
            accessibility: .id(AccessibilityIDs.descriptionLabel)
        )
        
        noButtonViewModel = .cancel(
            with: LocalizationConstants.ObjCStrings.BC_STRING_NO,
            accessibilityId: AccessibilityIDs.noButton
        )
        yesButtonViewModel = .primary(
            with: LocalizationConstants.ObjCStrings.BC_STRING_YES,
            accessibilityId: AccessibilityIDs.yesButton
        )
        
        noButtonViewModel.tapRelay
            .bindAndCatch(weak: self) { (self) in
                self.analyticsRecorder.record(event: AnalyticsEvent.sbCancelOrderGoBack)
                self.stateService.previousRelay.accept(())
            }
            .disposed(by: disposeBag)
        
        setupCancellationBinding()
    }
    
    private func setupCancellationBinding() {
        let cancellationResult = yesButtonViewModel
            .tapRelay
            .show(loader: uiUtilityProvider.loader, style: .circle)
            .flatMap(weak: self) { (self, _) in
                self.interactor.cancel()
            }
            .mapToResult()
            .hide(loader: uiUtilityProvider.loader)
            .share(replay: 1)

        cancellationResult
            .filter { $0.isSuccess }
            .mapToVoid()
            .bindAndCatch(weak: self) { (self) in
                self.analyticsRecorder.record(event: AnalyticsEvent.sbCancelOrderConfirmed)
                self.stateService.nextRelay.accept(())
            }
            .disposed(by: disposeBag)

        cancellationResult
            .mapToVoid()
            .bindAndCatch(to: dismissalRelay)
            .disposed(by: disposeBag)
            
        cancellationResult
            .filter { $0.isFailure }
            .mapToVoid()
            .bindAndCatch(weak: self) { (self) in
                self.cancellationDidFail()
            }
            .disposed(by: disposeBag)
    }
    
    private func cancellationDidFail() {
        uiUtilityProvider.alert.error(in: nil, action: nil)
        analyticsRecorder.record(event: AnalyticsEvent.sbCancelOrderError)
    }
    
    func viewDidLoad() {
        analyticsRecorder.record(event: AnalyticsEvent.sbCancelOrderPrompt)
    }
}
