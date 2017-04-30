//
//  UIAdaptableInputListView.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/24/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import RxSwift
import RxCocoa
import SwiftBaseViews
import SwiftInputView
import SwiftUtilities
import SwiftUIUtilities
import UIKit

/// Implement this protocol to provide delegation for UIAdapterInputListView.
public protocol UIAdaptableInputListViewDelegate: class {
    
    /// Provide default input for an InputViewDetailType instance.
    ///
    /// - Parameters:
    ///   - inputListView: The current UIAdaptableInputListView instance.
    ///   - input: An InputViewDetailType instance.
    /// - Returns: A String value.
    func inputListView(_ inputListView: UIAdaptableInputListView,
                       defaultValueFor input: InputViewDetailValidatorType)
        -> String?
}

/// This collection view combines InputData and UIAdaptableInputView and
/// automatically handles validation etc. As a result, it can handle multiple
/// input types, such as text/choice etc.
public final class UIAdaptableInputListView: UIBaseCollectionView {
    override public var presenterInstance: BaseCollectionViewPresenter? {
        return presenter
    }
    
    lazy var presenter: Presenter = Presenter(view: self)
    
    /// Presenter class for UIAdaptableInputListView.
    class Presenter: BaseCollectionViewPresenter {
    
        /// Return the current InputSectionHolder Array.
        public var inputs: [InputSectionHolder] { return rxInputs.value }
        
        /// These inputs will be used to populate the collection view. The
        /// variable is used to detect when inputs are added and bind the
        /// data source.
        var rxInputs: Variable<[InputSectionHolder]>
        
        weak var delegate: UIAdaptableInputListViewDelegate?
        
        /// For each
        var inputData: Set<InputData>
        
        /// We need a separate DisposeBag for text observers, so that when
        /// new InputData instances are created, we can simply reassign this
        /// variables to allow old disposables to terminate.
        var inputDataDisposeBag = DisposeBag()
        
        init(view: UIAdaptableInputListView) {
            rxInputs = Variable([])
            inputData = Set()
            super.init(view: view)
            
            // Disable scroll because we will be resizing this view to wrap
            // all cells, including spacing and insets. Therefore, it is best
            // to use it inside a UIScrollView.
            view.isScrollEnabled = false
            view.clipsToBounds = false
            view.register(with: UIInputCell.self)
            view.register(with: UIInputHeader.self)
            view.dataSource = self
            view.delegate = self
            
            setupInputObserver(for: view, with: self)
        }
        
        /// Stub out this method to avoid double-calling reloadData() during
        /// unit tests.
        ///
        /// - Parameters:
        ///   - view: The current UICollectionView instance.
        ///   - current: The current Presenter instance.
        func setupInputObserver(for view: UICollectionView,
                                with current: Presenter) {
            // When inputs are changed, dispose of all old Disposables,
            // adjust height and reload view.
            current.rxInputs.asObservable()
                .doOnNext({[weak current] _ in
                    current?.resetInputDataListeners(with: current)
                })
                .doOnNext({[weak current] in
                    current?.updateData(with: $0, with: current)
                })
                .doOnNext({[weak current, weak view] in
                    current?.adjustHeight(for: view, using: $0, with: current)
                })
                .doOnNext({[weak current, weak view] _ in
                    current?.reloadData(for: view)
                })
                .subscribe()
                .addDisposableTo(disposeBag)
        }
        
        /// Reassign the inputDataDisposeBag variable to clear old disposables.
        ///
        /// - Parameter current: The current Presenter instance.
        func resetInputDataListeners(with current: Presenter?) {
            current?.inputDataDisposeBag = DisposeBag()
        }
        
        /// When inputs change, we need to update all InputData instances as
        /// well.
        ///
        /// - Parameters:
        ///   - inputs: An Array of InputSectionHolder
        ///   - current: The current Presenter instance.
        func updateData(with inputs: [InputSectionHolder],
                        with current: Presenter?) {
            guard let current = current else {
                return
            }
            
            let disposeBag = current.inputDataDisposeBag
            
            let inputData = inputs
                .flatMap({$0.items})
                .flatMap({$0.items})
                .map({InputData.builder()
                    .with(input: $0)
                    .with(inputValidator: $0)
                    .with(disposeBag: disposeBag)
                    .build()})
            
            current.inputData = Set(inputData)
        }
        
        /// Get the view's height constraint. We separate this method out in
        /// order to override it during unit tests.
        ///
        /// - Parameter view: The current UIView instance.
        /// - Returns: An optional NSLayoutConstraint instance.
        func heightConstraint(for view: UIView?) -> NSLayoutConstraint? {
            return view?.heightConstraint
        }
        
        /// We need to adjust the input view's height, if necessary, once
        /// inputs are changed. For e.g., there may be less or more inputs
        /// than previously.
        ///
        /// - Parameters:
        ///   - view: The UIView whose height is requesting change.
        ///   - inputs: An Array of InputSectionHolder instances.
        ///   - current: The current Presenter instance.
        func adjustHeight(for view: UICollectionView?,
                          using inputs: [InputSectionHolder],
                          with current: Presenter?) {
            guard
                let view = view,
                let current = current,
                let height = heightConstraint(for: view)
            else {
                return
            }
            
            height.constant = current.fitHeight(using: inputs, with: current)
            
            UIView.animate(withDuration: Duration.short.rawValue) {
                view.superview?.layoutIfNeeded()
            }
        }
        
        /// Get the height that fits the current UICollectionView.
        ///
        /// - Parameters:
        ///   - inputs: An Array of InputSectionHolder instances.
        ///   - current: The current Presenter instance.
        /// - Returns: A CGFloat value.
        func fitHeight(using inputs: [InputSectionHolder],
                       with current: Presenter?) -> CGFloat {
            let sectionCount = inputs.count
            let inputCount = inputs.flatMap({$0.items}).count
            let itemSpace = current?.itemSpacing ?? 0
            let sectionSpace = current?.sectionSpacing ?? 0
            let sectionHeight = current?.sectionHeight ?? 0
            
            let height = inputs.totalHeight
            let totalIS = itemSpace * CGFloat(inputCount - 1)
            let totalSS = sectionSpace * 2 * CGFloat(sectionCount - 1)
            let totalSH = sectionHeight * CGFloat(sectionCount)
            let totalHeight = height + totalIS + totalSS + totalSH
            
            // When inputs are empty, height may be negative, so we default
            // to 0 if that is the case.
            return Swift.max(totalHeight, 0)
        }
        
        /// Get the InputData instance that corresponds to an input.
        ///
        /// - Parameter input: An InputViewDetailValidatorType instance.
        /// - Returns: An optional InputData instance.
        func inputData(for input: InputViewDetailValidatorType) -> InputData? {
            return inputData.filter({$0.inputIdentifier == input.identifier}).first
        }
        
        /// Get the field that corresponds to an InputViewDetailValidatorType
        /// instance. We do this by traversing the InputSectionHolder Array
        /// to get an index tuple of (Int, Int, Int), construct an IndexPath
        /// from the first 2 indexes, get the appropriate UICollectionViewCell
        /// and then query its subviews for the inputField.
        ///
        /// - Parameters:
        ///   - input: An InputViewDetailValidatorType instance.
        ///   - view: The current UIAdaptableInputListView instance.
        /// - Returns: An optional InputFieldType instance.
        func inputField(for input: InputViewDetailValidatorType,
                        with view: UIAdaptableInputListView) -> InputFieldType? {
            let inputViewType = UIAdaptableInputView.self
            
            guard
                let i = inputs.index(for: input),
                let cell = view.cellForItem(at: IndexPath(row: i.0, section: i.1)),
                let inputView = cell.firstSubview(ofType: inputViewType),
                let inputField = inputView.inputFields.element(at: i.2)
            else {
                debugException()
                return nil
            }
            
            return inputField
        }
        
        /// Clear input for an InputViewDetailValidatorType instance.
        ///
        /// - Parameters:
        ///   - input: An InputViewDetailValidatorType instance.
        ///   - view: The current UIAdaptableInputListView instance.
        /// - Returns: A Bool value that represent whether the operation 
        ///            succeeded.
        @discardableResult
        func clearValue(for input: InputViewDetailValidatorType,
                        with view: UIAdaptableInputListView) -> Bool {
            return enterValue(for: input, with: nil, with: view)
        }
        
        /// Enter input for an InputViewDetailValidatorType instance.
        ///
        /// - Parameters:
        ///   - input: An InputViewDetailValidatorType instance.
        ///   - value: An optional String value.
        ///   - view: The current UIAdaptableInputListView instance.
        /// - Returns: A Bool value that represents whether the operation 
        ///            succeeded.
        @discardableResult
        func enterValue(for input: InputViewDetailValidatorType,
                        with value: String?,
                        with view: UIAdaptableInputListView) -> Bool {
            guard let inputField = inputField(for: input, with: view) else {
                return false
            }
            
            inputField.text = value
            return true
        }
        
        /// Clear all inputs.
        ///
        /// - Parameter view: The current UIAdaptableInputListView instance.
        func clearAllValues(with view: UIAdaptableInputListView) {
            view.allSubviews(ofType: InputFieldType.self).forEach({$0.text = nil})
        }
    }
}

// MARK: - Getters.
public extension UIAdaptableInputListView {
    
    /// When we set inputs, pass them to the presenter.
    public var inputs: [InputSectionHolder] {
        get { return presenter.rxInputs.value }
        set { presenter.rxInputs.value = newValue }
    }
    
    /// We expose inputData to allow external observers.
    public var inputData: Set<InputData> {
        return presenter.inputData
    }
    
    /// Expose this to allow external observers.
    public var inputsObservable: Observable<[InputSectionHolder]> {
        return presenter.rxInputs.asObservable()
    }
    
    /// When delegate is set, pass it to presenter.
    public var inputListViewDelegate: UIAdaptableInputListViewDelegate? {
        get { return presenter.delegate }
        set { presenter.delegate = newValue }
    }
}

// MARK: - Input values.
public extension UIAdaptableInputListView {
    
    /// Get all inputFields.
    ///
    /// - Returns: An Array of InputFieldType instances.
    public func inputFields() -> [InputFieldType] {
        return allSubviews(ofType: InputFieldType.self)
    }
    
    /// Clear input for an InputViewDetailValidatorType instance.
    ///
    /// - Parameter input: An InputViewDetailValidatorType instance.
    /// - Returns: A Bool value that represents whether the operation succeeded.
    @discardableResult
    public func clearValue(for input: InputViewDetailValidatorType) -> Bool {
        return presenter.clearValue(for: input, with: self)
    }
    
    /// Clear input for an InputViewDetailValidatorType instance.
    public func clearAllValues() {
        presenter.clearAllValues(with: self)
    }
    
    /// Enter input for an InputViewDetailValidatorType instance.
    ///
    /// - Parameters:
    ///   - input: An InputViewDetailValidatorType instance.
    ///   - value: An optional String value.
    /// - Returns: A Bool value that represents whether the operation succeeded.
    @discardableResult
    func enterValue(for input: InputViewDetailValidatorType,
                    with value: String?) -> Bool {
        return presenter.enterValue(for: input, with: value, with: self)
    }
}

extension UIAdaptableInputListView.Presenter {
    
    /// Override itemSpacing to provide a different default value.
    override var itemSpacing: CGFloat {
        return decorator?.itemSpacing ?? Space.smaller.value ?? 0
    }
}

// MARK: - UICollectionViewDataSource
extension UIAdaptableInputListView.Presenter: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return inputs.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        guard let section = inputs.element(at: section) else {
            debugException()
            return 0
        }
        
        return section.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cellClass = UIInputCell.self
        
        guard
            let view = collectionView as? UIAdaptableInputListView,
            let cell = collectionView.deque(with: cellClass, for: indexPath),
            let section = inputs.element(at: indexPath.section),
            let holder = section.items.element(at: indexPath.row)
        else {
            debugException()
            return UICollectionViewCell()
        }
        
        let builder = InputViewBuilder(from: holder.inputDetails)
        let config = InputViewBuilderConfig(from: holder.inputDecorators)
        let inputView = UIAdaptableInputView(with: builder, and: config)
        let contentView = cell.contentView
        
        // We need to remove all views and constraints to prevent
        // duplicates, since cells are reused.
        contentView.subviews.forEach({$0.removeFromSuperview()})
        contentView.constraints.forEach(contentView.removeConstraint)
        contentView.addSubview(inputView)
        contentView.addFitConstraints(for: inputView)
        
        // Let inputData listen to text changes. We need to find the
        // right inputData that corresponds the an InputFieldType instance.
        let inputData = self.inputData
        let disposeBag = self.inputDataDisposeBag
        let delegate = self.delegate
        
        for (index, inputField) in inputView.inputFields.enumerated() {
            guard
                let input = holder.items.element(at: index),
                let data = inputData.filter({
                    $0.inputIdentifier == input.identifier
                }).first
            else {
                debugException()
                continue
            }
            
            inputField.rxText.asObservable()
                .map({$0 ?? ""})
                .doOnNext({[weak data] in data?.onNext($0)})
                .subscribe()
                .addDisposableTo(disposeBag)
            
            // We set default value after setting up text observers in order
            // to emit it. Only set default value if it is available.
            if let value = delegate?.inputListView(view, defaultValueFor: input) {
                inputField.text = value
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let viewClass = UIInputHeader.self
        let inputs = self.inputs
        
        if
            let view = collectionView.deque(with: viewClass, at: indexPath),
            let section = inputs.element(at: indexPath.section)?.section
        {
            // We need to remove all subviews and constraints in case cells
            // are reused, leading to duplicate views.
            view.subviews.forEach({$0.removeFromSuperview()})
            view.constraints.forEach(view.removeConstraint)
            
            let builder = section.viewBuilder()
            let config = section.viewConfig()
            view.populateSubviews(with: builder)
            config.configure(for: view)
            return view
        } else {
            return UICollectionReusableView()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension UIAdaptableInputListView.Presenter {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let holder = inputs
            .element(at: indexPath.section)?
            .items
            .element(at: indexPath.row)
        else {
            debugException()
            return CGSize.zero
        }
        
        let width = collectionView.bounds.width
        let height = holder.largestHeight
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int)
        -> CGSize
    {
        let width = collectionView.bounds.width
        let height = sectionHeight
        return CGSize(width: width, height: height)
    }
}

/// UICollectionViewCell subclass.
final class UIInputCell: UICollectionViewCell {}

/// UICollectionReusableView subclass
final class UIInputHeader: UICollectionReusableView {}

extension UIInputHeader: ReusableViewIdentifierType {
    public static var kind: ReusableViewKind { return .header }
}

// MARK: - Unused.
extension UIAdaptableInputListView.Presenter: RxCollectionViewDataSourceType {
    public func collectionView(_ collectionView: UICollectionView,
                               observedEvent: Event<[InputSectionHolder]>) {
        collectionView.reloadData()
    }
}
