//
//  WalletCryptoServiceTests.swift
//  PlatformKitTests
//
//  Created by Daniel Huri on 10/03/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

@testable import Blockchain
import DIKit
import PlatformKit
import RxBlocking
import RxSwift
import ToolKit
import XCTest

class WalletCryptoServiceTests: XCTestCase {

    var walletManager: WalletManager!
    var service: WalletCryptoServiceAPI!
    
    override func setUp() {
        super.setUp()
        // Force JS initialization before hand
        let container = modules {
            DependencyContainer.platformKit;
            DependencyContainer.blockchain;
        }
        let walletManager: WalletManager = container.resolve()
        _ = walletManager.fetchJSContext()
        let service: WalletCryptoServiceAPI = container.resolve()
        self.walletManager = walletManager
        self.service = service
    }
    
    func testDecryption() {
        let key = "keykeykeykeykey"
        let data = "datadatadatadatadata"
        let pbkdf2Iterations: Int = 100
        do {
            let encrypted = try service
                .encrypt(pair: KeyDataPair(key: key, data: data), pbkdf2Iterations: pbkdf2Iterations)
                .toBlocking()
                .first()
            guard let encryptedData = encrypted else {
                XCTFail("encryptedData is nil")
                return
            }
            let decryptedData = try service
                .decrypt(pair: KeyDataPair(key: key, data: encryptedData), pbkdf2Iterations: pbkdf2Iterations)
                .toBlocking()
                .first()
            XCTAssertEqual(data, decryptedData)
        } catch let error {
            XCTFail("Decryption failed with error: \(error.localizedDescription)")
        }
    }
}
