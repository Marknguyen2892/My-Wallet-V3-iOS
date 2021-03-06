//
//  FiatValue.swift
//  PlatformKit
//
//  Created by Chris Arriola on 1/17/19.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import BigInt
import ToolKit

public struct FiatComparisonError: Error {
    let currencyCode1: FiatCurrency
    let currencyCode2: FiatCurrency
}

public struct FiatValue {
        
    /// The currency
    public let currencyType: FiatCurrency
    public let amount: Decimal
    
    // TODO: Reverse the logic. store the minor amount and compute the major amount
    public var minorAmount: BigInt {
        BigInt(stringLiteral: string)
    }
    
    public var displayMajorValue: Decimal {
        minorAmount.toDisplayMajor(maxDecimalPlaces: currency.maxDecimalPlaces)
    }
        
    /// Returns the minor
    public var string: String {
        var minorDecimal = amount * pow(10, currency.maxDecimalPlaces)
        minorDecimal = minorDecimal.roundTo(places: 0)
        return "\(minorDecimal)"
    }

    fileprivate init(currency: FiatCurrency, amount: Decimal) {
        self.amount = amount
        self.currencyType = currency
    }
    
    public init(minor: BigInt, currency: FiatCurrency) {
        let major = minor.toDisplayMajor(maxDecimalPlaces: currency.maxDecimalPlaces)
        self.init(currency: currency, amount: major)
    }
}

// MARK: - Setup

extension FiatValue {
    
    init(currencyCode: String, amount: Decimal) {
        self.currencyType = FiatCurrency(rawValue: currencyCode)!
        self.amount = amount
    }
    
    public init(minor: String, currency: FiatCurrency, locale: Locale = Locale.current) {
        var amount = Decimal(string: minor, locale: locale) ?? 0
        amount /= pow(10, currency.maxDecimalPlaces)
        self.init(currency: currency, amount: amount)
    }
}

extension FiatValue {

    @available(*, deprecated, message: "Superseded by `create(amountString: String, currency: FiatCurrency, locale: Locale)`")
    public static func create(amountString: String,
                              currencyCode: String,
                              locale: Locale = Locale.current) -> FiatValue {
        let amount = Decimal(string: amountString, locale: locale) ?? 0
        return FiatValue(currencyCode: currencyCode, amount: amount)
    }

    @available(*, deprecated, message: "Superseded by `create(amount: Decimal, currency: FiatCurrency)`")
    public static func create(amount: Decimal, currencyCode: String) -> FiatValue {
        FiatValue(currencyCode: currencyCode, amount: amount)
    }
    
    @available(*, deprecated, message: "Superseded by `zero(currency: FiatCurrency)`")
    public static func zero(currencyCode: String) -> FiatValue {
        FiatValue(currencyCode: currencyCode, amount: 0.0)
    }

    /// Creates a FiatValue from a provided amount in String and currency code.
    /// If the amountString is invalid, the resulting FiatValue amount will be 0.
    ///
    /// - Parameters:
    ///   - amountString: the amount as a String
    ///   - currency: the currency
    /// - Returns: the FiatValue
    public static func create(amountString: String,
                              currency: FiatCurrency,
                              locale: Locale = Locale.current) -> FiatValue {
        let amount = Decimal(string: amountString, locale: locale) ?? 0
        return FiatValue(currency: currency, amount: amount)
    }
    
    public static func zero(currency: FiatCurrency) -> FiatValue {
        FiatValue(currency: currency, amount: 0.0)
    }
    
    public static func create(amount: Decimal, currency: FiatCurrency) -> FiatValue {
        FiatValue(currency: currency, amount: amount)
    }

    /// Converts this value into a corresponding CryptoValue given an exchange rate for a given currency
    ///
    /// - Parameters:
    ///   - exchangeRate: the cost of 1 unit of cryptoCurrency provided in FiatValue
    ///   - cryptoCurrency: the currency to convert to
    /// - Returns: the converted FiatValue in CryptoValue
    public func convertToCryptoValue(exchangeRate: FiatValue, cryptoCurrency: CryptoCurrency) -> CryptoValue {
        let locale = Locale.Posix
        let exchangeRate = exchangeRate.amount
        let cryptoMajorValue = amount / exchangeRate
        let cryptoMajorValueString = (cryptoMajorValue as NSDecimalNumber).description(withLocale: locale)
        guard let cryptoValue = CryptoValue.createFromMajorValue(string: cryptoMajorValueString, assetType: cryptoCurrency, locale: locale) else {
            fatalError("Failed to convert to CryptoValue. cryptoMajorValueString: \(cryptoMajorValueString), cryptoCurrency: \(cryptoCurrency)")
        }
        return cryptoValue
    }
}

extension FiatValue: Money {
    
    public var currencyCode: String {
        currency.code
    }

    public var isZero: Bool {
        amount == 0
    }

    public var isPositive: Bool {
        amount > 0
    }
    
    public var isNegative: Bool {
        amount < 0
    }

    public var symbol: String {
        let locale = NSLocale.current as NSLocale
        return locale.displayName(forKey: NSLocale.Key.currencySymbol, value: currency.code) ?? ""
    }

    public var maxDecimalPlaces: Int {
        let formattedString = toDisplayString(includeSymbol: false, locale: Locale.US)
        let components = formattedString.split(separator: ".")
        guard let lastComponent = components.last, components.count > 1 else {
            return 0
        }
        return lastComponent.count
    }

    public var maxDisplayableDecimalPlaces: Int {
        maxDecimalPlaces
    }

    public func toDisplayString(includeSymbol: Bool = true,
                                locale: Locale = Locale.current) -> String {
        toDisplayString(
            includeSymbol: includeSymbol,
            format: .fullLength,
            locale: locale
        )
    }
    
    public func toDisplayString(includeSymbol: Bool = true,
                                format: NumberFormatter.CurrencyFormat = .fullLength,
                                locale: Locale = Locale.current) -> String {
        /// Determine how many fraction digits should be formatted from a `FiatValue`.
        /// If the rhs of the decimal point is different than zero -> display two digits,
        /// otherwise, display without the fractional part
        let maxFractionDigits: Int
        switch format {
        case .fullLength:
            maxFractionDigits = currency.maxDecimalPlaces
        case .shortened where abs(amount - amount.roundTo(places: 0)) > 0:
            maxFractionDigits = currency.maxDecimalPlaces
        case .shortened:
            maxFractionDigits = 0
        }

        let formatter = FiatFormatterProvider.shared.formatter(
            locale: locale,
            fiatValue: self,
            maxFractionDigits: maxFractionDigits
        )
        return formatter.format(amount: amount, includeSymbol: includeSymbol)
    }
}

// MARK: - Operators

extension FiatValue: Hashable, Equatable {
    private static func ensureComparable(value: FiatValue, other: FiatValue) throws {
        if value.currencyType != other.currencyType {
            throw FiatComparisonError(currencyCode1: value.currencyType, currencyCode2: other.currencyType)
        }
    }
    
    public static func max(_ x: FiatValue, _ y: FiatValue) throws -> FiatValue {
        try ensureComparable(value: x, other: y)
        return try x > y ? x : y
    }
    
    public static func min(_ x: FiatValue, _ y: FiatValue) throws -> FiatValue {
        try ensureComparable(value: x, other: y)
        return try x < y ? x : y
    }
    
    public static func > (lhs: FiatValue, rhs: FiatValue) throws -> Bool {
        try ensureComparable(value: lhs, other: rhs)
        return lhs.amount > rhs.amount
    }
    
    public static func < (lhs: FiatValue, rhs: FiatValue) throws -> Bool {
        try ensureComparable(value: lhs, other: rhs)
        return lhs.amount < rhs.amount
    }
    
    public static func >= (lhs: FiatValue, rhs: FiatValue) throws -> Bool {
        try ensureComparable(value: lhs, other: rhs)
        return lhs.amount >= rhs.amount
    }

    public static func <= (lhs: FiatValue, rhs: FiatValue) throws -> Bool {
        try ensureComparable(value: lhs, other: rhs)
        return lhs.amount <= rhs.amount
    }

    public static func +(lhs: FiatValue, rhs: FiatValue) throws -> FiatValue {
        try ensureComparable(value: lhs, other: rhs)
        return FiatValue(currency: lhs.currencyType, amount: lhs.amount + rhs.amount)
    }

    public static func -(lhs: FiatValue, rhs: FiatValue) throws -> FiatValue {
        try ensureComparable(value: lhs, other: rhs)
        return FiatValue(currency: lhs.currencyType, amount: lhs.amount - rhs.amount)
    }

    public static func *(lhs: FiatValue, rhs: FiatValue) throws -> FiatValue {
        try ensureComparable(value: lhs, other: rhs)
        return FiatValue(currency: lhs.currencyType, amount: lhs.amount * rhs.amount)
    }
    
    public static func /(lhs: FiatValue, rhs: FiatValue) throws -> FiatValue {
        try ensureComparable(value: lhs, other: rhs)
        return FiatValue(currency: lhs.currencyType, amount: lhs.amount / rhs.amount)
    }

    public static func +=(lhs: inout FiatValue, rhs: FiatValue) throws {
        lhs = try lhs + rhs
    }

    public static func -=(lhs: inout FiatValue, rhs: FiatValue) throws {
        lhs = try lhs - rhs
    }

    public static func *= (lhs: inout FiatValue, rhs: FiatValue) throws {
        lhs = try lhs * rhs
    }
    
    public static func /= (lhs: inout FiatValue, rhs: FiatValue) throws {
        lhs = try lhs / rhs
    }
        
    /// Calculates the value of `self` before a given percentage change
    /// e.g if the current value is `100` and the percentage of change is `10%`,
    /// the `percentageChange` expected value would be `0.1`.
    public func value(before percentageChange: Double) -> FiatValue {
        let percentageChange = percentageChange + 1
        guard percentageChange != 0 else {
            return .zero(currency: currencyType)
        }
        return .create(
            amount: amount / Decimal(percentageChange),
            currency: currencyType
        )
    }
}

// MARK: FiatFormatterProvider

private class FiatFormatterProvider {

    static let shared = FiatFormatterProvider()

    private var formatterMap = [String: NumberFormatter]()
    private let queue = DispatchQueue(label: "FiatFormatterProvider.queue")

    /// Returns `NumberFormatter`. This method executes on a dedicated queue.
    func formatter(locale: Locale, fiatValue: FiatValue, maxFractionDigits: Int) -> NumberFormatter {
        var formatter: NumberFormatter!
        queue.sync { [unowned self] in
            let mapKey = key(locale: locale, fiatValue: fiatValue)
            if let matchingFormatter = formatterMap[mapKey] {
                matchingFormatter.maximumFractionDigits = maxFractionDigits
                formatter = matchingFormatter
            } else {
                formatter = NumberFormatter(
                    locale: locale,
                    currencyCode: fiatValue.currency.code,
                    maxFractionDigits: maxFractionDigits
                )
                self.formatterMap[mapKey] = formatter
            }
            
        }
        return formatter
    }

    private func key(locale: Locale, fiatValue: FiatValue) -> String {
        "\(locale.identifier)_\(fiatValue.currency.code)"
    }
}
