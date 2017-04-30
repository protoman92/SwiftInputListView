//
//  InputHolder.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/24/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftBaseViews
import SwiftInputView
import SwiftUIUtilities
import SwiftUtilities

/// Use this typealias to avoid too many generics.
public typealias InputHolder = ListItemHolder<InputViewDetailValidatorType>

public extension ListItemHolderType where Item == InputViewDetailValidatorType {
    
    /// We can simply return items here and it will be correctly cast.
    public var inputDetails: [InputViewDetailType] { return items }
    
    /// Get the associated decorators.
    public var inputDecorators: [InputViewDecoratorType] {
        return items.map({$0.decorator})
    }
    
    /// Get the largest height, based on all stored InputViewDetailType.
    public var largestHeight: CGFloat { return inputDetails.largestHeight }
    
    public var section: ListSectionType? { return items.first?.section }
}
