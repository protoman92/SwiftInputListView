//
//  UIAdaptableInputListView.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/24/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import RxSwift
import RxCocoa
import SwiftInputView
import SwiftUtilities
import SwiftUIUtilities
import UIKit

/// This collection view combines InputData and UIAdaptableInputView and
/// automatically handles validation etc. As a result, it can handle multiple
/// input types, such as text/choice etc.
public final class UIAdaptableInputListView: UICollectionView {
    lazy var presenter: Presenter = Presenter(view: self)
    
    /// Presenter class for UIAdaptableInputListView.
    class Presenter: BaseViewPresenter {
        
        /// Decorator to configure appearance.
        fileprivate let decorator: Variable<InputListViewDecoratorType?>
        
        /// These inputs will be used to populate the collection view. The
        /// variable is used to detect when inputs are added and bind the
        /// data source.
        fileprivate var inputs: Variable<[InputSectionHolderType]>
        
        /// For each
        fileprivate var inputData: Set<InputData>
        
        fileprivate let disposeBag = DisposeBag()
        
        init(view: UIAdaptableInputListView) {
            decorator = Variable(nil)
            inputs = Variable([])
            inputData = Set()
            super.init(view: view)
            view.register(with: UIInputCell.self)
            view.delegate = self
            
            decorator.asObservable()
                .doOnNext({[weak view] _ in view?.reloadData()})
                .subscribe()
                .addDisposableTo(disposeBag)
            
            inputs.asObservable()
                .doOnNext({[weak self] in
                    self?.updateData(with: $0, with: self)
                })
                .doOnNext({[weak self, weak view] in
                    self?.adjustHeight(for: view, using: $0, with: self)
                })
                .bind(to: view.rx.items(
                    cellIdentifier: UIInputCell.identifier,
                    cellType: UIInputCell.self
                ), curriedArgument: {[weak self] in
                    self?.setupCell(at: $0.0, for: $0.1, with: $0.2, with: self)
                })
                .addDisposableTo(disposeBag)
        }
        
        /// When inputs change, we need to update all InputData instances as
        /// well.
        ///
        /// - Parameters:
        ///   - inputs: An Array of InputHolder
        ///   - current: The current Presenter instance.
        func updateData(with inputs: [InputHolder], with current: Presenter?) {
            guard let current = current else {
                return
            }
            
            let disposeBag = current.disposeBag
            
            let inputData = inputs.flatMap({$0.inputs})
                .map({InputData.builder()
                    .with(input: $0)
                    .with(inputValidator: $0)
                    .with(disposeBag: disposeBag)
                    .build()})
            
            current.inputData = Set(inputData)
        }
        
        /// Setup a UIInputCell instance. We build a dynamic instance of
        /// UIAdaptableInputView and fit it to this cell.
        ///
        /// - Parameters:
        ///   - row: The row at which the cell is found.
        ///   - input: An InputHolder instance.
        ///   - cell: A UIInputCell instance.
        ///   - presenter: The current Presenter instance.
        func setupCell(at row: Int,
                       for holder: InputHolder,
                       with cell: UIInputCell,
                       with current: Presenter?) {
            let builder = InputViewBuilder(from: holder.inputDetails)
            let config = InputViewBuilderConfig(from: holder.inputDecorators)
            let view = UIAdaptableInputView(with: builder, and: config)
            let contentView = cell.contentView
            
            // We need to remove all views and constraints to prevent 
            // duplicates, since cells are reused.
            contentView.subviews.forEach({$0.removeFromSuperview()})
            contentView.constraints.forEach({contentView.removeConstraint($0)})
            contentView.addSubview(view)
            contentView.addFitConstraints(for: view)
            
            // Let inputData listen to text changes. We need to find the
            // right inputData that corresponds the an InputFieldType instance.
            guard let current = current else {
                return
            }
            
            let inputData = current.inputData
            let disposeBag = current.disposeBag
            
            for (index, inputField) in view.inputFields.enumerated() {
                guard
                    let textObs = inputField.rxText?.asObservable(),
                    let input = holder.inputs.element(at: index),
                    let data = inputData.filter({
                        $0.inputIdentifier == input.identifier
                    }).first
                else {
                    debugException()
                    continue
                }
                
                textObs.map({$0 ?? ""})
                    .doOnNext({[weak data] in data?.onNext($0)})
                    .subscribe()
                    .addDisposableTo(disposeBag)
            }
        }
        
        /// We need to adjust the input view's height, if necessary, once
        /// inputs are changed. For e.g., there may be less or more inputs
        /// than previously.
        ///
        /// - Parameters:
        ///   - view: The UIView whose height is requesting change.
        ///   - inputs: An Array of InputHolder instances.
        ///   - current: The current Presenter instance.
        func adjustHeight(for view: UICollectionView?,
                          using inputs: [InputHolder],
                          with current: Presenter?) {
            guard
                let view = view,
                let current = current,
                let height = view.heightConstraint
            else {
                return
            }
            
            // When inputs are empty, height may be negative.
            let fitHeight = current.fitHeight(using: inputs, with: current)
            height.constant = Swift.max(fitHeight, 0)
            
            UIView.animate(withDuration: Duration.short.rawValue) {
                view.superview?.layoutIfNeeded()
            }
        }
        
        /// Get the height that fits the current UICollectionView.
        ///
        /// - Parameters:
        ///   - inputs: An Array of InputHolder instances.
        ///   - current: The current Presenter instance.
        /// - Returns: A CGFloat value.
        func fitHeight(using inputs: [InputHolder],
                       with current: Presenter?) -> CGFloat {
            let inputCount = inputs.count
            let height = inputs.map({$0.largestHeight}).reduce(0, +)
            let spacing = current?.itemSpacing ?? 0
            return height + spacing * CGFloat(inputCount - 1)
        }
    }
}

public extension UIAdaptableInputListView {
    
    /// When we set inputs, pass them to the presenter.
    public var inputs: [InputSectionHolderType] {
        get { return presenter.inputs.value }
        set { presenter.inputs.value = newValue }
    }
    
    /// We expose inputData to allow external observers.
    public var inputData: Set<InputData> {
        return presenter.inputData
    }
    
    /// When decorator is set, this view will be reloaded.
    public var decorator: InputListViewDecoratorType? {
        get { return presenter.decorator.value }
        set { presenter.decorator.value = newValue }
    }
}

final class UIInputCell: UICollectionViewCell {}

extension UIAdaptableInputListView.Presenter: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return inputs.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        guard let section = inputs.value.element(at: section) else {
            debugException()
            return 0
        }
        
        return section.inputHolders.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        guard
            let cell = collectionView.dequeReusableCell(
                with: UIInputCell.self,
                for: indexPath),
            let holder = inputs.value
                .element(at: indexPath.section)?
                .inputHolders
                .element(at: indexPath.row)
        else {
            debugException()
            return UICollectionViewCell()
        }
        
        let builder = InputViewBuilder(from: holder.inputDetails)
        let config = InputViewBuilderConfig(from: holder.inputDecorators)
        let view = UIAdaptableInputView(with: builder, and: config)
        let contentView = cell.contentView
        
        // We need to remove all views and constraints to prevent
        // duplicates, since cells are reused.
        contentView.subviews.forEach({$0.removeFromSuperview()})
        contentView.constraints.forEach({contentView.removeConstraint($0)})
        contentView.addSubview(view)
        contentView.addFitConstraints(for: view)
        
        // Let inputData listen to text changes. We need to find the
        // right inputData that corresponds the an InputFieldType instance.
        let inputData = self.inputData
        let disposeBag = self.disposeBag
        
        for (index, inputField) in view.inputFields.enumerated() {
            guard
                let textObs = inputField.rxText?.asObservable(),
                let input = holder.inputs.element(at: index),
                let data = inputData.filter({
                    $0.inputIdentifier == input.identifier
                }).first
            else {
                debugException()
                continue
            }
            
            textObs.map({$0 ?? ""})
                .doOnNext({[weak data] in data?.onNext($0)})
                .subscribe()
                .addDisposableTo(disposeBag)
        }
        
        return cell
    }
}

extension UIAdaptableInputListView.Presenter: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int)
        -> CGFloat
    {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int)
        -> CGFloat
    {
        return itemSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard
            let section = inputs.value.element(at: indexPath.section),
            let holder = section.inputHolders.element(at: indexPath.row)
        else {
            debugException()
            return CGSize.zero
        }
        
        let decorators = holder.inputDetails
        
        // Take the maximum height out of all inputs in this Array.
        let height = decorators.flatMap({$0.inputViewHeight}).max()
        
        return CGSize(width: collectionView.bounds.width,
                      height: (height ?? Size.medium.value) ?? 0)
    }
}

extension UIAdaptableInputListView.Presenter: InputListViewDecoratorType {
    public var itemSpacing: CGFloat? {
        return decorator.value?.itemSpacing ?? Space.smaller.value
    }
}
