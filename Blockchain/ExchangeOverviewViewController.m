//
//  ExchangeOverviewViewController.m
//  Blockchain
//
//  Created by kevinwu on 10/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeOverviewViewController.h"
#import "ExchangeCreateViewController.h"
#import "ExchangeProgressViewController.h"
#import "ConfirmStateViewController.h"
#import "ExchangeModalView.h"
#import "BCNavigationController.h"
#import "BCLine.h"
#import "ExchangeTableViewCell.h"
#import "RootService.h"

#import "ExchangeDetailView.h"

#define EXCHANGE_VIEW_HEIGHT 70
#define EXCHANGE_VIEW_OFFSET 30
#define CELL_HEIGHT 65

#define CELL_IDENTIFIER_EXCHANGE_CELL @"exchangeCell"

@interface ExchangeOverviewViewController () <UITableViewDelegate, UITableViewDataSource, CloseButtonDelegate, ConfirmStateDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *trades;
@property (nonatomic) ExchangeCreateViewController *createViewController;
@property (nonatomic) BOOL didFinishShift;
@end

@implementation ExchangeOverviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    
    NSArray *availableStates = [app.wallet availableUSStates];
    
    if (availableStates.count > 0) {
        [self showStates:availableStates];
    } else {
        [app.wallet getExchangeTrades];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    navigationController.headerTitle = BC_STRING_EXCHANGE;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.didFinishShift) {
        BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
        [navigationController showBusyViewWithLoadingText:BC_STRING_LOADING_LOADING_TRANSACTIONS];
        [app.wallet performSelector:@selector(getExchangeTrades) withObject:nil afterDelay:ANIMATION_DURATION];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.didFinishShift = NO;
}

- (void)setupSubviewsIfNeeded
{
    if (!self.tableView) {
        [self setupExchangeButtonView];
        [self setupTableView];
    }
}

- (void)setupExchangeButtonView
{
    CGFloat windowWidth = WINDOW_WIDTH;
    UIView *newExchangeView = [[UIView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT + EXCHANGE_VIEW_OFFSET, windowWidth, EXCHANGE_VIEW_HEIGHT)];
    newExchangeView.backgroundColor = [UIColor whiteColor];
    
    BCLine *topLine = [[BCLine alloc] initWithYPosition:newExchangeView.frame.origin.y - 1];
    [self.view addSubview:topLine];
    
    BCLine *bottomLine = [[BCLine alloc] initWithYPosition:newExchangeView.frame.origin.y + newExchangeView.frame.size.height];
    [self.view addSubview:bottomLine];
    
    CGFloat exchangeLabelOriginX = 80;
    CGFloat chevronWidth = 15;
    CGFloat exchangeLabelHeight = 30;
    UILabel *newExchangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(exchangeLabelOriginX, newExchangeView.frame.size.height/2 - exchangeLabelHeight/2, windowWidth - exchangeLabelOriginX - chevronWidth, exchangeLabelHeight)];
    newExchangeLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_MEDIUM];
    newExchangeLabel.text = BC_STRING_NEW_EXCHANGE;
    newExchangeLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [newExchangeView addSubview:newExchangeLabel];
    
    CGFloat exchangeIconImageViewWidth = 50;
    UIImageView *exchangeIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, newExchangeView.frame.size.height/2 - exchangeIconImageViewWidth/2, exchangeIconImageViewWidth, exchangeIconImageViewWidth)];
    exchangeIconImageView.image = [UIImage imageNamed:@"exchange_small"];
    [newExchangeView addSubview:exchangeIconImageView];
    
    UIImageView *chevronImageView = [[UIImageView alloc] initWithFrame:CGRectMake(newExchangeView.frame.size.width - 8 - chevronWidth, newExchangeView.frame.size.height/2 - chevronWidth/2, chevronWidth, chevronWidth)];
    chevronImageView.image = [UIImage imageNamed:@"chevron_right"];
    chevronImageView.contentMode = UIViewContentModeScaleAspectFit;
    chevronImageView.tintColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    [newExchangeView addSubview:chevronImageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(newExchangeClicked)];
    [newExchangeView addGestureRecognizer:tapGesture];
    
    [self.view addSubview:newExchangeView];
}

- (void)setupTableView
{
    CGFloat windowWidth = WINDOW_WIDTH;
    CGFloat yOrigin = DEFAULT_HEADER_HEIGHT + EXCHANGE_VIEW_OFFSET + EXCHANGE_VIEW_HEIGHT + 16;
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, yOrigin, windowWidth, self.view.frame.size.height - 16 - yOrigin) style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

- (void)showStates:(NSArray *)states
{
    ConfirmStateViewController *confirmStateViewController = [[ConfirmStateViewController alloc] initWithStates:states];
    confirmStateViewController.delegate = self;
    [self.navigationController pushViewController:confirmStateViewController animated:NO];
    self.navigationController.viewControllers = @[confirmStateViewController];
}

- (void)newExchangeClicked
{
    [self showCreateExchangeControllerAnimated:YES];
}

- (void)showCreateExchangeControllerAnimated:(BOOL)animated
{
    ExchangeCreateViewController *createViewController = [ExchangeCreateViewController new];
    [self.navigationController pushViewController:createViewController animated:animated];
    self.createViewController = createViewController;
}

- (void)didGetExchangeTrades:(NSArray *)trades
{
    if (self.didFinishShift) {
        self.didFinishShift = NO;
        BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
        [navigationController hideBusyView];
        [self setupSubviewsIfNeeded];
        self.trades = trades;
        [self.tableView reloadData];
    } else if (trades.count == 0) {
        [self showCreateExchangeControllerAnimated:NO];
        self.navigationController.viewControllers = @[self.createViewController];
        return;
    } else {
        [self setupSubviewsIfNeeded];
        self.trades = trades;
        [self.tableView reloadData];
    }
}

- (void)didGetExchangeRate:(NSDictionary *)result
{
    [self.createViewController didGetExchangeRate:result];
}

- (void)didGetQuote:(NSDictionary *)result
{
    [self.createViewController didGetQuote:result];
}

- (void)didGetAvailableEthBalance:(NSDictionary *)result
{
    [self.createViewController didGetAvailableEthBalance:result];
}

- (void)didGetAvailableBtcBalance:(NSDictionary *)result
{
    [self.createViewController didGetAvailableBtcBalance:result];
}

- (void)didBuildExchangeTrade:(NSDictionary *)tradeInfo
{
    [self.createViewController didBuildExchangeTrade:tradeInfo];
}

- (void)didShiftPayment:(NSDictionary *)info
{
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    [navigationController hideBusyView];
    
    ExchangeModalView *exchangeModalView = [[ExchangeModalView alloc] initWithFrame:self.view.frame description:BC_STRING_EXCHANGE_DESCRIPTION_SENDING_FUNDS imageName:@"exchange_sending" bottomText:[NSString stringWithFormat:BC_STRING_STEP_ARGUMENT_OF_ARGUMENT, 1, 3] closeButtonText:BC_STRING_CLOSE];
    exchangeModalView.delegate = self;
    BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeNone showHeader:YES headerText:BC_STRING_EXCHANGE_TITLE_SENDING_FUNDS view:exchangeModalView];
    
    if (!self.navigationController) {
        self.createViewController.navigationController.viewControllers = @[self, self.createViewController];
    }
    [self.navigationController presentViewController:modalViewController animated:YES completion:nil];
}

#pragma mark - Confirm State delegate

- (void)didConfirmState:(UINavigationController *)navigationController
{
    ExchangeCreateViewController *createViewController = [ExchangeCreateViewController new];
    [navigationController pushViewController:createViewController animated:NO];
    self.createViewController = createViewController;
    navigationController.viewControllers = @[createViewController];
}

#pragma mark - Close button delegate

- (void)closeButtonClicked
{
    self.didFinishShift = YES;
    [self.navigationController.presentedViewController dismissViewControllerAnimated:YES completion:^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 45)];
    view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, tableView.frame.size.width, 30)];
    label.textColor = COLOR_TEXT_DARK_GRAY;
    label.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL_MEDIUM];
    
    [view addSubview:label];
    
    label.text = [BC_STRING_ORDER_HISTORY uppercaseString];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.trades.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ExchangeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_EXCHANGE_CELL];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ExchangeTableViewCell" owner:nil options:nil] objectAtIndex:0];
        ExchangeTrade *trade = [self.trades objectAtIndex:indexPath.row];
        [cell configureWithTrade:trade];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ExchangeProgressViewController *exchangeProgressVC = [[ExchangeProgressViewController alloc] init];
    exchangeProgressVC.trade = [self.trades objectAtIndex:indexPath.row];
    BCNavigationController *navigationController = [[BCNavigationController alloc] initWithRootViewController:exchangeProgressVC title:BC_STRING_EXCHANGE];
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end