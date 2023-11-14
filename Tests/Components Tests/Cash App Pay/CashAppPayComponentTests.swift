//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import XCTest

#if canImport(AdyenCashAppPay)
    @_spi(AdyenInternal) @testable import Adyen
    @testable import AdyenCashAppPay
    import Foundation
    @testable import PayKit
    import UIKit

    final class CashAppPayComponentTests: XCTestCase {
        
        var paymentMethodString = """
            {
              "configuration" : {
                "scopeId" : "asd",
                "clientId" : "asd"
              },
              "name" : "Cash App Pay",
              "type" : "cashapp"
            }
        """
        
        lazy var paymentMethod: CashAppPayPaymentMethod = {
            try! JSONDecoder().decode(CashAppPayPaymentMethod.self, from: paymentMethodString.data(using: .utf8)!)
        }()
        
        var context: AdyenContext!
        
        var oneTimeAction: PaymentAction {
            let moneyAmount = Money(amount: UInt(5000), currency: .USD)
            return PaymentAction.oneTimePayment(scopeID: "test",
                                                money: moneyAmount)
        }
        
        var onFileAction: PaymentAction {
            PaymentAction.onFilePayment(scopeID: "test",
                                        accountReferenceID: nil)
        }
        
        var oneTimeGrant: CustomerRequest.Grant {
            .init(id: "grantId1", customerID: "testId", action: oneTimeAction, status: .ACTIVE, type: .ONE_TIME, channel: .IN_APP, createdAt: Date(), updatedAt: Date(), expiresAt: nil)
        }
        
        var onFileGrant: CustomerRequest.Grant {
            .init(id: "onFileGrantId1", customerID: "testId", action: onFileAction, status: .ACTIVE, type: .EXTENDED, channel: .IN_APP, createdAt: Date(), updatedAt: Date(), expiresAt: nil)
        }
        
        override func setUpWithError() throws {
            guard #available(iOS 13.0, *) else {
                // XCTestCase does not respect @available so we have skip all tests here
                throw XCTSkip("Unsupported iOS version")
            }
            
            try super.setUpWithError()
            context = Dummy.context
        }

        override func tearDownWithError() throws {
            context = nil
            try super.tearDownWithError()
        }
        
        @available(iOS 13.0, *)
        func testUIConfiguration() {
            var componentStyle = FormComponentStyle()
            
            componentStyle.backgroundColor = .green
            
            // switch
            componentStyle.toggle.title.backgroundColor = .green
            componentStyle.toggle.title.color = .yellow
            componentStyle.toggle.title.font = .systemFont(ofSize: 5)
            componentStyle.toggle.title.textAlignment = .left
            componentStyle.toggle.backgroundColor = .magenta
            
            let config = CashAppPayConfiguration(redirectURL: URL(string: "test")!, showsStorePaymentMethodField: true, style: componentStyle)
            let sut = CashAppPayComponent(paymentMethod: paymentMethod, context: context, configuration: config)
            
            UIApplication.shared.keyWindow?.rootViewController = sut.viewController
            wait(for: .milliseconds(300))
            
            let storeDetailsItemView: FormToggleItemView? = sut.viewController.view.findView(with: "AdyenCashAppPay.CashAppPayComponent.storeDetailsItem")
            let storeDetailsItemTitleLabel: UILabel? = sut.viewController.view.findView(with: "AdyenCashAppPay.CashAppPayComponent.storeDetailsItem.titleLabel")
            
            // Test store card details switch
            XCTAssertEqual(storeDetailsItemView?.backgroundColor, .magenta)
            XCTAssertEqual(storeDetailsItemTitleLabel?.backgroundColor, .green)
            XCTAssertEqual(storeDetailsItemTitleLabel?.textAlignment, .left)
            XCTAssertEqual(storeDetailsItemTitleLabel?.textColor, .yellow)
            XCTAssertEqual(storeDetailsItemTitleLabel?.font, .systemFont(ofSize: 5))

            XCTAssertEqual(sut.viewController.view.backgroundColor, .green)
        }

        @available(iOS 13.0, *)
        func testSwitchVisible() {
            
            let config = CashAppPayConfiguration(redirectURL: URL(string: "test")!, showsStorePaymentMethodField: true)
            let sut = CashAppPayComponent(paymentMethod: paymentMethod, context: context, configuration: config)
            
            UIApplication.shared.keyWindow?.rootViewController = sut.viewController
            wait(for: .milliseconds(300))
            
            let storeDetailsToggleView: UIView? = sut.viewController.view.findView(with: "AdyenCashAppPay.CashAppPayComponent.storeDetailsItem")
            
            XCTAssertNotNil(storeDetailsToggleView)
        }
        
        @available(iOS 13.0, *)
        func testSwitchHidden() {
            
            let config = CashAppPayConfiguration(redirectURL: URL(string: "test")!, showsStorePaymentMethodField: false)
            let sut = CashAppPayComponent(paymentMethod: paymentMethod, context: context, configuration: config)
            
            UIApplication.shared.keyWindow?.rootViewController = sut.viewController
            wait(for: .milliseconds(300))
            
            let storeDetailsToggleView: UIView? = sut.viewController.view.findView(with: "AdyenCashAppPay.CashAppPayComponent.storeDetailsItem")
            
            XCTAssertNil(storeDetailsToggleView)
        }
        
        @available(iOS 13.0, *)
        func testStopLoading() {
            let config = CashAppPayConfiguration(redirectURL: URL(string: "test")!, showsStorePaymentMethodField: true)
            let sut = CashAppPayComponent(paymentMethod: paymentMethod, context: context, configuration: config)
            
            UIApplication.shared.keyWindow?.rootViewController = sut.viewController
            wait(for: .milliseconds(300))

            UIApplication.shared.keyWindow?.rootViewController = sut.viewController
            wait(for: .milliseconds(300))
            
            XCTAssertFalse(sut.cashAppPayButton.showsActivityIndicator)
            sut.cashAppPayButton.showsActivityIndicator = true
            sut.stopLoadingIfNeeded()
            XCTAssertFalse(sut.cashAppPayButton.showsActivityIndicator)
        }
        
        @available(iOS 13.0, *)
        func testViewWillAppearShouldSendTelemetryEvent() throws {
            
            // Given
            let analyticsProviderMock = AnalyticsProviderMock()
            let context = AdyenContext(apiContext: Dummy.apiContext,
                                       payment: Dummy.payment,
                                       analyticsProvider: analyticsProviderMock)
            let config = CashAppPayConfiguration(redirectURL: URL(string: "test")!)
            let sut = CashAppPayComponent(paymentMethod: paymentMethod, context: context, configuration: config)

            // When
            sut.viewWillAppear(viewController: sut.viewController)

            // Then
            XCTAssertEqual(analyticsProviderMock.sendTelemetryEventCallsCount, 1)
        }
        
        @available(iOS 13.0, *)
        func testComponent_ShouldPaymentMethodTypeBeCashAppPay() throws {
            // Given
            let expectedPaymentMethodType: PaymentMethodType = .cashAppPay
            let config = CashAppPayConfiguration(redirectURL: URL(string: "test")!)
            let sut = CashAppPayComponent(paymentMethod: paymentMethod, context: context, configuration: config)
            
            // Action
            let paymentMethodType = sut.paymentMethod.type
            
            // Assert
            XCTAssertEqual(paymentMethodType, expectedPaymentMethodType)
        }
        
        @available(iOS 13.0, *)
        func testComponent_ShouldRequireModalPresentation() throws {
            // Given
            let config = CashAppPayConfiguration(redirectURL: URL(string: "test")!)
            let sut = CashAppPayComponent(paymentMethod: paymentMethod, context: context, configuration: config)
            
            // Assert
            XCTAssertTrue(sut.requiresModalPresentation)
        }
        
        @available(iOS 13.0, *)
        func testOneTimeSubmitDetails() {
            let config = CashAppPayConfiguration(redirectURL: URL(string: "test")!)
            let sut = CashAppPayComponent(paymentMethod: paymentMethod, context: context, configuration: config)
            
            let delegate = PaymentComponentDelegateMock()
            sut.delegate = delegate
            UIApplication.shared.keyWindow?.rootViewController = sut.viewController
            
            let delegateExpectation = expectation(description: "PaymentComponentDelegate must be called when submit button is clicked.")
            let finalizationExpectation = expectation(description: "Component should finalize.")
            delegate.onDidSubmit = { data, component in
                XCTAssertTrue(component === sut)
                XCTAssertTrue(data.paymentMethod is CashAppPayDetails)
                let details = data.paymentMethod as! CashAppPayDetails
                
                XCTAssertEqual(details.grantId, "grantId1")
                XCTAssertNil(details.cashtag)
                XCTAssertEqual(details.customerId, "testId")
                XCTAssertNil(details.onFileGrantId)

                sut.finalizeIfNeeded(with: true, completion: {
                    finalizationExpectation.fulfill()
                })
                delegateExpectation.fulfill()
            }
            
            wait(for: .milliseconds(300))
            
            sut.submitApprovedRequest(with: [oneTimeGrant], profile: .init(id: "testId", cashtag: "testtag"))
            
            waitForExpectations(timeout: 10, handler: nil)
        }
        
        @available(iOS 13.0, *)
        func testOneTimeAndOnFileSubmitDetails() {
            let config = CashAppPayConfiguration(redirectURL: URL(string: "test")!)
            let sut = CashAppPayComponent(paymentMethod: paymentMethod, context: context, configuration: config)
            
            let delegate = PaymentComponentDelegateMock()
            sut.delegate = delegate
            UIApplication.shared.keyWindow?.rootViewController = sut.viewController
            
            let delegateExpectation = expectation(description: "PaymentComponentDelegate must be called when submit button is clicked.")
            let finalizationExpectation = expectation(description: "Component should finalize.")
            delegate.onDidSubmit = { data, component in
                XCTAssertTrue(component === sut)
                XCTAssertTrue(data.paymentMethod is CashAppPayDetails)
                let details = data.paymentMethod as! CashAppPayDetails
                
                XCTAssertEqual(details.grantId, "grantId1")
                XCTAssertEqual(details.customerId, "testId")
                XCTAssertEqual(details.cashtag, "testtag")
                XCTAssertEqual(details.onFileGrantId, "onFileGrantId1")

                sut.finalizeIfNeeded(with: true, completion: {
                    finalizationExpectation.fulfill()
                })
                delegateExpectation.fulfill()
            }
            
            wait(for: .milliseconds(300))
            
            sut.submitApprovedRequest(with: [oneTimeGrant, onFileGrant], profile: .init(id: "testId", cashtag: "testtag"))
            
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
#endif
