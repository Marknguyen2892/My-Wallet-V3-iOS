//
//  DashboardViewController.swift
//  Blockchain
//
//  Created by Daniel Huri on 22/10/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit
import PlatformUIKit
import BuySellUIKit
import RxCocoa
import RxRelay
import RxSwift

/// A view controller that displays the dashboard
final class DashboardViewController: BaseScreenViewController {

    // MARK: - Outlets
    
    private let tableView = UITableView()
    private var refreshControl: UIRefreshControl!
    
    // MARK: - Injected
    
    private let presenter: DashboardScreenPresenter
    
    // MARK: - Accessors
    
    private let disposeBag = DisposeBag()

    // MARK: - Lazy Properties

    private lazy var router: DashboardRouter = {
        .init(routing: AppCoordinator.shared)
    }()
    
    // MARK: - Setup
    
    init() {
        self.presenter = DashboardScreenPresenter()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        presenter.action
            .emit(onNext: { [weak self] action in
                self?.execute(action: action)
            })
            .disposed(by: disposeBag)
        presenter.setup()
        tableView.reloadData()
        presenter.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isTranslucent = false
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        set(barStyle: .lightContent(),
            leadingButtonStyle: .drawer,
            trailingButtonStyle: .qrCode)
        titleViewStyle = .text(value: LocalizationConstants.DashboardScreen.title)
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.layoutToSuperview(axis: .horizontal, usesSafeAreaLayoutGuide: true)
        tableView.layoutToSuperview(axis: .vertical, usesSafeAreaLayoutGuide: true)
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(AnnouncementTableViewCell.self)
        tableView.register(FiatCustodialBalancesTableViewCell.self)
        tableView.register(NoticeTableViewCell.self)
        tableView.registerNibCell(TotalBalanceTableViewCell.self)
        tableView.registerNibCell(HistoricalBalanceTableViewCell.self)
        tableView.separatorColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
        tableView.refreshControl = refreshControl
    }
    
    // MARK: - Actions
    
    private func execute(action: DashboardCollectionAction) {
        switch action {
        case .announcement(let action):
            execute(announcementAction: action)
        case .notice(let action):
            execute(noticeAction: action)
        case .fiatBalance(let action):
            execute(fiatBalanceAction: action)
        case .actionScreen(let action):
            execute(walletScreenAction: action)
        }
    }
    
    private func execute(fiatBalanceAction: DashboardItemDisplayAction<FiatBalanceCollectionViewPresenter>) {
        let previousCellIndex = (presenter.indexByCellType[.notice] ?? presenter.indexByCellType[.totalBalance]!)
        let index = previousCellIndex + 1
        let indexPaths = [IndexPath(item: index, section: 0)]
        switch fiatBalanceAction {
        case .show where !presenter.fiatBalanceState.isVisible:
            tableView.insertRows(at: indexPaths, with: .automatic)
            presenter.fiatBalanceState = .visible(index: index)
        case .hide where presenter.fiatBalanceState.isVisible:
            tableView.deleteRows(at: indexPaths, with: .automatic)
            presenter.fiatBalanceState = .hidden
        default:
            break
        }
    }
    
    private func execute(noticeAction: DashboardItemDisplayAction<NoticeViewModel>) {
        let previousCellIndex = presenter.indexByCellType[.totalBalance]!
        let index = previousCellIndex + 1
        let indexPaths = [IndexPath(item: index, section: 0)]
        switch noticeAction {
        case .show where !presenter.noticeState.isVisible:
            tableView.insertRows(at: indexPaths, with: .automatic)
            presenter.noticeState = .visible(index: index)
        case .hide where presenter.noticeState.isVisible:
            tableView.deleteRows(at: indexPaths, with: .automatic)
            presenter.noticeState = .hidden
        default:
            break
        }
    }
    
    private func execute(announcementAction: AnnouncementDisplayAction) {
        switch announcementAction {
        case .hide:
            switch presenter.cardState {
            case .visible(index: let index):
                tableView.deleteRows(at: [.init(row: index, section: 0)], with: .automatic)
            case .hidden:
                break
            }
            presenter.cardState = .hidden
        case .show:
            switch presenter.announcementCardArrangement {
            case .top:
                if !presenter.cardState.isVisible {
                    tableView.insertRows(at: [.firstRowInFirstSection], with: .automatic)
                    presenter.cardState = .visible(index: 0)
                } else {
                    tableView.reloadRows(at: [.firstRowInFirstSection], with: .automatic)
                }
            case .bottom:
                /// Must not be `nil`. Otherwise there is a presentation error
                let index = presenter.announcementCellIndex!
                let indexPath = IndexPath(row: index, section: 0)
                if !presenter.cardState.isVisible {
                    tableView.insertRows(at: [indexPath], with: .automatic)
                    presenter.cardState = .visible(index: index)
                } else {
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            case .none:
                break
            }
        case .none:
            break
        }
    }
    
    private func execute(walletScreenAction: DashboardItemDisplayAction<CurrencyType>) {
        guard case let .show(currencyType) = walletScreenAction else { return }
        router.showWalletActionScreen(for: currencyType)
    }
    
    // MARK: - Navigation
    
    override func navigationBarLeadingButtonPressed() {
        presenter.navigationBarLeadingButtonPressed()
    }
    
    override func navigationBarTrailingButtonPressed() {
        presenter.navigationBarTrailingButtonPressed()
    }
    
    // MARK: - UITableView refresh
    
    @objc
    private func refresh() {
        presenter.refresh()
        refreshControl.endRefreshing()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        presenter.cellCount
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let type = presenter.cellArrangement[indexPath.row]
        switch type {
        case .announcement:
            cell = announcementCell(for: indexPath)
        case .fiatCustodialBalances:
            cell = fiatCustodialBalancesCell(for: indexPath)
        case .totalBalance:
            cell = balanceCell(for: indexPath)
        case .crypto(let currency):
            cell = assetCell(for: indexPath, currency: currency)
        case .notice:
            cell = noticeCell(for: indexPath)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let type = presenter.cellArrangement[indexPath.row]
        switch type {
        case .announcement,
             .notice,
             .totalBalance,
             .fiatCustodialBalances:
            break
        case .crypto(let currency):
            router.showDetailsScreen(for: currency)
        }
    }
        
    // MARK: - Accessors
    
    private func fiatCustodialBalancesCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(FiatCustodialBalancesTableViewCell.self, for: indexPath)
        cell.presenter = presenter.fiatBalanceCollectionViewPresenter
        return cell
    }
    
    private func announcementCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(AnnouncementTableViewCell.self, for: indexPath)
        cell.viewModel = presenter.announcementCardViewModel
        return cell
    }
    
    private func balanceCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(TotalBalanceTableViewCell.self, for: indexPath)
        cell.presenter = presenter.totalBalancePresenter
        return cell
    }
    
    private func assetCell(for indexPath: IndexPath, currency: CryptoCurrency) -> UITableViewCell {
        let cell = tableView.dequeue(HistoricalBalanceTableViewCell.self, for: indexPath)
        cell.presenter = presenter.historicalBalancePresenter(by: indexPath.row)
        return cell
    }
    
    private func noticeCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(NoticeTableViewCell.self, for: indexPath)
        cell.viewModel = presenter.noticeViewModel
        return cell
    }
}
