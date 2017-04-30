//
//  InputSection.swift
//  TestApplication
//
//  Created by Hai Pham on 4/25/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftBaseViews
import SwiftUtilities
import UIKit

/// Use this typealias to avoid too many generics.
///
/// We need to use this because UIAdaptableInputListView is a special case:
/// there may be multiple input items on each cell.
public typealias InputSectionHolder = ListSectionHolder<InputHolder>

extension ListSectionHolderType where Item == InputHolder {
    /// We need to enumerate the holders Array, after which we enumerate each
    /// holder.
    ///
    /// - Parameter input: An InputViewDetailValidatorType instance.
    /// - Returns: A (Int, Int) tuple.
    public func index(for input: InputViewDetailValidatorType) -> (Int, Int)? {
        for (holderIndex, holder) in items.enumerated() {
            for (inputIndex, stored) in holder.items.enumerated() {
                if input.identifier == stored.identifier {
                    return (holderIndex, inputIndex)
                }
            }
        }
        
        return nil
    }
}

public extension Sequence where
    Iterator.Element: ListSectionHolderType,
    Iterator.Element.Item == InputHolder
{
    /// Get the total height, based on the largestHeight of each 
    /// InputHolderType.
    public var totalHeight: CGFloat {
        return flatMap({$0.items}).map({$0.largestHeight}).reduce(0, +)
    }
    
    /// Return the index at which an InputViewDetailValidatorType is found.
    ///
    /// - Parameter input: An InputViewDetailValidatorType instance.
    /// - Returns: An optional (Int, Int, Int) tuple. The first index is
    ///            the section holder's index within the Array, the second
    ///            index is the input holder's index within the section holder,
    ///            and the third one is the input's index within the input
    ///            holder.
    public func index(for input: InputViewDetailValidatorType) -> (Int, Int, Int)? {
        for (index, holder) in enumerated() {
            if let holderIndex = holder.index(for: input) {
                return (index, holderIndex.0, holderIndex.1)
            }
        }
        
        return nil
    }
}
