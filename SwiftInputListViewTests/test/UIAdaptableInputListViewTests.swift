//
//  UIAdaptableInputListViewTests.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/26/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import UIKit
import SwiftBaseViews
import SwiftUtilities
import SwiftUtilitiesTests
import SwiftUIUtilities
import RxSwift
import RxTest
import RxBlocking
import UIKit
import XCTest

typealias Presenter = UIAdaptableInputListView.Presenter

class UIAdaptableInputListViewTests: XCTestCase {
    fileprivate var disposeBag: DisposeBag!
    fileprivate var presenter: MockPresenter!
    fileprivate var scheduler: TestScheduler!
    fileprivate var inputListView: UIAdaptableInputListView!
    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let tries = 1000

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        
        inputListView = UIAdaptableInputListView(
            frame: CGRect.zero,
            collectionViewLayout: UICollectionViewLayout()
        )
        
        presenter = MockPresenter(view: inputListView)
        inputListView.presenter = presenter
        inputListView.layoutSubviews()
    }

    func test_setInputs_shouldTriggerReload() {
        // Setup
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have worked")
        let tries = self.tries
        
        // When
        inputListView.inputsObservable
            .take(tries)
            .doOnNext({[unowned self] in
                self.validateHeight(using: $0, with: self.presenter)
            })
            .cast(to: Any.self)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        (0..<tries - 1).forEach({_ in
            synchronized(inputListView) {
                inputListView.inputs = InputDetail.randomInputSectionHolders
            }
        })
        
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        // Then
        XCTAssertEqual(presenter.fake_heightConstraint.methodCount, tries)
        XCTAssertEqual(presenter.fake_resetInputDataListeners.methodCount, tries)
        XCTAssertEqual(presenter.fake_updateData.methodCount, tries)
        XCTAssertEqual(presenter.fake_adjustHeight.methodCount, tries)
        XCTAssertEqual(presenter.fake_fitHeight.methodCount, tries)
        
        // Reload data is called twice due to decorator variable.
        XCTAssertEqual(presenter.fake_reloadData.methodCount, tries + 1)
    }
    
    func validateHeight(using inputs: [InputSectionHolder],
                        with presenter: MockPresenter) {
        XCTAssertTrue(presenter.heightConstraint.constant >= 0)
        XCTAssertTrue(presenter.heightConstraint.constant >= inputs.totalHeight)
    }
    
    func test_enterInputValues_shouldWork() {
        // Setup
        let inputs = InputDetail.inputHolders.sectionHolders
        let subject = PublishSubject<Void>()
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have worked")
        inputListView.inputs = inputs
        
        let inputData = inputListView.inputData
        
        // When
        let validationCheck = subject.asObservable()
            .flatMap(inputData.rxValidate)
            .doOnNext({[unowned self] in
                self.validateInputs(with: inputData, using: $0)
            })
            .take(tries)
            .cast(to: Any.self)
        
        let inputStateCheck = subject.asObservable()
            .flatMap(inputData.rxAllRequiredInputFilled)
            .doOnNext({[unowned self] in
                self.validateFilled(with: inputData, using: $0)
            })
            .take(tries)
            .cast(to: Any.self)
        
        Observable
            .merge(validationCheck, inputStateCheck)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        (0..<tries).forEach({_ in
            defer { inputListView.clearAllValues() }
            
            InputDetail.allValues.forEach({
                let value = String.random(withLength: Int.random(0, 5))
                inputListView.enterValue(for: $0, with: value)
            })
            
            subject.onNext()
        })
        
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        // Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, tries * 2)
    }
    
    func validateInputs(with inputData: Set<InputData>,
                        using notification: InputNotificationType) {
        let hasErrors = notification.hasErrors
        let outputs = notification.outputs
        
        for data in inputData {
            let content = data.inputContent
            let validator = data.inputValidator!
            
            if let output = outputs[data.inputIdentifier] {
                if content.isEmpty && data.isRequired {
                    XCTAssertTrue(hasErrors)
                    XCTAssertEqual(output, "input.error.required".localized)
                } else if content.isNotEmpty {
                    do {
                        try validator.validate(input: data, against: inputData)
                    } catch let error {
                        XCTAssertTrue(hasErrors)
                        XCTAssertEqual(error.localizedDescription, output)
                    }
                }
            }
        }
    }
    
    func validateFilled(with inputData: Set<InputData>, using filled: Bool) {
        XCTAssertEqual(inputData.allRequiredInputFilled(), filled)
    }
}

class MockPresenter: UIAdaptableInputListView.Presenter {
    fileprivate let fake_heightConstraint = FakeDetails.builder().build()
    fileprivate let fake_resetInputDataListeners = FakeDetails.builder().build()
    fileprivate let fake_updateData = FakeDetails.builder().build()
    fileprivate let fake_adjustHeight = FakeDetails.builder().build()
    fileprivate let fake_fitHeight = FakeDetails.builder().build()
    fileprivate let fake_reloadData = FakeDetails.builder().build()
    fileprivate let heightConstraint = NSLayoutConstraint()

    override func heightConstraint(for view: UIView?) -> NSLayoutConstraint? {
        fake_heightConstraint.onMethodCalled(withParameters: view)
        return heightConstraint
    }
    
    override func resetInputDataListeners(with current: UIAdaptableInputListView.Presenter?) {
        fake_resetInputDataListeners.onMethodCalled(withParameters: nil)
        super.resetInputDataListeners(with: current)
    }
    
    override func updateData(with inputs: [InputSectionHolder],
                             with current: UIAdaptableInputListView.Presenter?) {
        fake_updateData.onMethodCalled(withParameters: (inputs, current))
        super.updateData(with: inputs, with: current)
    }
    
    override func adjustHeight(for view: UICollectionView?,
                               using inputs: [InputSectionHolder],
                               with current: UIAdaptableInputListView.Presenter?) {
        fake_adjustHeight.onMethodCalled(withParameters: (view, inputs, current))
        super.adjustHeight(for: view, using: inputs, with: current)
    }
    
    override func fitHeight(using inputs: [InputSectionHolder],
                            with current: UIAdaptableInputListView.Presenter?) -> CGFloat {
        fake_fitHeight.onMethodCalled(withParameters: (inputs, current))
        return super.fitHeight(using: inputs, with: current)
    }
    
    override func reloadData(for view: UICollectionView?) {
        fake_reloadData.onMethodCalled(withParameters: view)
        return super.reloadData(for: view)
    }
    
    override func enterValue(for input: InputViewDetailValidatorType,
                             with value: String?,
                             with view: UIAdaptableInputListView) -> Bool {
        let value = value ?? ""
        let data = inputData(for: input)!
        data.onNext(value)
        XCTAssertEqual(data.inputContent, value)
        return true
    }
    
    override func clearValue(for input: InputViewDetailValidatorType,
                             with view: UIAdaptableInputListView) -> Bool {
        let data = inputData(for: input)!
        data.onNext("")
        XCTAssertEqual(data.inputContent, "")
        return true
    }
    
    override func clearAllValues(with view: UIAdaptableInputListView) {
        inputData.forEach({$0.onNext("")})
        XCTAssertEqual(inputData.flatMap({$0.inputContent}).reduce("", +), "")
    }
}
