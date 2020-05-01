//
//  AddCardLabelContentPresenter.swift
//  Blockchain
//
//  Created by Alex McGregor on 4/8/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformUIKit
import PlatformKit
import RxSwift
import RxRelay

final class AddCardLabelContentPresenter: LabelContentPresenting {
    
    typealias PresentationState = LabelContentAsset.State.LabelItem.Presentation
    
    let stateRelay = BehaviorRelay<PresentationState>(value: .loading)
    var state: Observable<PresentationState> {
        stateRelay.asObservable()
    }
    
    // MARK: - Private Accessors
    
    private let interactor: AddCardLabelContentInteractor
    private let disposeBag = DisposeBag()
    
    init(service: CardListServiceAPI, tierLimitsProviding: TierLimitsProviding) {
        interactor = AddCardLabelContentInteractor(
            service: service,
            tierLimitsProviding: tierLimitsProviding
        )
        Observable
            .combineLatest(
                interactor.state,
                interactor.descriptorObservable
            )
            .map { .init(with: $0.0, descriptors: $0.1) }
            .bind(to: stateRelay)
            .disposed(by: disposeBag)
    }
}