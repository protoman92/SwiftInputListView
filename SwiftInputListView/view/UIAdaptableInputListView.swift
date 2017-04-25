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
            
            // Disable scroll because we will be resizing this view to wrap
            // all cells, including spacing and insets. Therefore, it is best
            // to use it inside a UIScrollView.
            view.isScrollEnabled = false
            view.clipsToBounds = false
            view.register(with: UIInputCell.self)
            view.register(with: UIInputHeader.self)
            view.dataSource = self
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
                .doOnNext({[weak self, weak view] _ in
                    self?.reloadData(for: view)
                })
                .subscribe()
                .addDisposableTo(disposeBag)
        }
        
        /// When inputs change, we need to update all InputData instances as
        /// well.
        ///
        /// - Parameters:
        ///   - inputs: An Array of InputSectionHolderType
        ///   - current: The current Presenter instance.
        func updateData(with inputs: [InputSectionHolderType],
                        with current: Presenter?) {
            guard let current = current else {
                return
            }
            
            let disposeBag = current.disposeBag
            
            let inputData = inputs
                .flatMap({$0.inputHolders})
                .flatMap({$0.inputs})
                .map({InputData.builder()
                    .with(input: $0)
                    .with(inputValidator: $0)
                    .with(disposeBag: disposeBag)
                    .build()})
            
            current.inputData = Set(inputData)
        }
        
        /// We need to adjust the input view's height, if necessary, once
        /// inputs are changed. For e.g., there may be less or more inputs
        /// than previously.
        ///
        /// - Parameters:
        ///   - view: The UIView whose height is requesting change.
        ///   - inputs: An Array of InputSectionHolderType instances.
        ///   - current: The current Presenter instance.
        func adjustHeight(for view: UICollectionView?,
                          using inputs: [InputSectionHolderType],
                          with current: Presenter?) {
            guard
                let view = view,
                let current = current,
                let height = view.heightConstraint
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
        ///   - inputs: An Array of InputSectionHolderType instances.
        ///   - current: The current Presenter instance.
        /// - Returns: A CGFloat value.
        func fitHeight(using inputs: [InputSectionHolderType],
                       with current: Presenter?) -> CGFloat {
            let sectionCount = inputs.count
            let inputCount = inputs.flatMap({$0.inputHolders}).count
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
        
        /// Reload data for the current collection view.
        ///
        /// - Parameter view: A UICollectionView instance.
        func reloadData(for view: UICollectionView?) {
            view?.reloadData()
        }
    }
}

// MARK: - Getters.
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

// MARK: - UICollectionViewDataSource
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
        let cellClass = UIInputCell.self
        
        guard
            let cell = collectionView.deque(with: cellClass, for: indexPath),
            let section = inputs.value.element(at: indexPath.section),
            let holder = section.inputHolders.element(at: indexPath.row)
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
        contentView.constraints.forEach(contentView.removeConstraint)
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
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let viewClass = UIInputHeader.self
        let inputs = self.inputs.value
        
        if
            let view = collectionView.deque(with: viewClass, at: indexPath),
            let section = inputs.element(at: indexPath.section)?.inputSection
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
extension UIAdaptableInputListView.Presenter: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let spacing = sectionSpacing ?? 0
        
        // We set top and bottom insets to space out sections.
        return UIEdgeInsets(top: spacing, left: 0, bottom: spacing, right: 0)
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
        guard let holder = inputs.value
            .element(at: indexPath.section)?
            .inputHolders
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
        let height = sectionHeight ?? 0
        return CGSize(width: width, height: height)
    }
}

// MARK: - InputListViewDecoratorType
extension UIAdaptableInputListView.Presenter: InputListViewDecoratorType {
    public var sectionHeight: CGFloat? {
        // Only use header if there are more than 1 section.
        guard inputs.value.count > 1 else { return 0 }
        return decorator.value?.sectionHeight ?? Size.small.value
    }
    
    public var itemSpacing: CGFloat? {
        return decorator.value?.itemSpacing ?? Space.smaller.value
    }
    
    public var sectionSpacing: CGFloat? {
        return decorator.value?.sectionSpacing ?? Space.small.value
    }
}

/// UICollectionViewCell subclass.
final class UIInputCell: UICollectionViewCell {}

/// UICollectionReusableView subclass
final class UIInputHeader: UICollectionReusableView {}

extension UIInputHeader: ReusableViewIdentifierType {
    public static var kind: ReusableViewKind {
        return .header
    }
}

// MARK: - Unused.
extension UIAdaptableInputListView.Presenter: RxCollectionViewDataSourceType {
    public func collectionView(_ collectionView: UICollectionView,
                               observedEvent: Event<[InputSectionHolderType]>) {
        collectionView.reloadData()
    }
}
