//
//  WalletPickerScreenPresenter.swift
//  Blockchain
//
//  Created by Alex McGregor on 5/5/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import Localization
import PlatformKit
import RxCocoa
import RxRelay
import RxSwift

public final class WalletPickerScreenPresenter {
    
    // MARK: - Navigation Properties
    
    let trailingButton: Screen.Style.TrailingButton = .close
    
    let leadingButton: Screen.Style.LeadingButton = .none
    
    let titleViewStyle: Screen.Style.TitleView = .text(value: LocalizationConstants.WalletPicker.title)
    
    var barStyle: Screen.Style.Bar {
        .darkContent()
    }
    
    var sectionObservable: Observable<[WalletPickerSectionViewModel]> {
        _ = setup
        return sectionRelay
            .map { WalletPickerSectionViewModel(items: $0) }
            .map { [$0] }
            .asObservable()
    }
    
    private let interactor: WalletPickerInteractor
    private let sectionRelay = BehaviorRelay<[WalletPickerCellItem]>(value: [])
    private let disposeBag = DisposeBag()
    private let showTotalBalance: Bool

    private lazy var setup: Void = {
        let cellInteractors = showTotalBalance ? interactor.interactors : interactor.balanceCellInteractors
        cellInteractors
            .map { items -> [WalletPickerCellItem] in
                items.map { .init(cellInteractor: $0) }
            }
            .bindAndCatch(to: sectionRelay)
            .disposed(by: disposeBag)
    }()

    public init(showTotalBalance: Bool, interactor: WalletPickerInteractor) {
        self.interactor = interactor
        self.showTotalBalance = showTotalBalance
    }
    
    func record(selection: WalletPickerSelection) {
        interactor.record(selection: selection)
    }
}
