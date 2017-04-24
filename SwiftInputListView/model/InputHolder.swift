//
//  InputHolder.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/24/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftInputView
import SwiftUIUtilities
import SwiftUtilities

/// Implement this protocol to provide an Array of InputViewDetailValidatorType.
public protocol InputHolderType {
    var inputs: [InputViewDetailValidatorType] { get }
    
    /// We can simply return inputs here.
    var inputDetails: [InputViewDetailType] { get }
    
    /// We can simply return inputs here.
    var inputDecorators: [InputViewDecoratorType] { get }
}

public extension InputHolderType {
    /// Get the largest height, based on all stored InputViewDetailType.
    public var largestHeight: CGFloat {
        return inputDetails.flatMap({$0.inputViewHeight}).max() ?? 0
    }
}

/// Use this struct to carry InputViewDetailValidatorType instances, instead 
/// of having an Array of InputViewDetailValidatorType Array for multiple 
/// inputs.
public struct InputHolder {
    fileprivate var allInputs: [InputViewDetailValidatorType]
    
    fileprivate init() {
        allInputs = []
    }
    
    public final class Builder {
        fileprivate var holder: InputHolder
        
        fileprivate init() {
            holder = InputHolder()
        }
        
        /// Add a InputViewDetailType instance.
        ///
        /// - Parameter input: A InputViewDetailValidatorType instance.
        /// - Returns: The current Builder instance.
        public func add(input: InputViewDetailValidatorType) -> Builder {
            holder.allInputs.append(input)
            return self
        }
        
        /// Set allInputs.
        ///
        /// - Parameter inputs: A sequence of InputViewDetailValidatorType.
        /// - Returns: The current Builder instance.
        public func with<S: Sequence>(inputs: S) -> Builder
            where S.Iterator.Element == InputViewDetailValidatorType
        {
            holder.allInputs = inputs.map(eq)
            return self
        }
        
        /// Set allInputs.
        ///
        /// - Parameter inputs: A sequence of InputViewDetailValidatorType.
        /// - Returns: The current Builder instance.
        public func with<S: Sequence>(inputs: S) -> Builder
            where S.Iterator.Element: InputViewDetailValidatorType
        {
            holder.allInputs = inputs.map(eq)
            return self
        }
        
        public func build() -> InputHolder {
            return holder
        }
    }
}

extension InputHolder: Collection {
    public var startIndex: Int {
        return inputs.startIndex
    }
    
    public var endIndex: Int {
        return inputs.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return Swift.min(i + 1, endIndex)
    }
    
    public subscript(index: Int) -> InputViewDetailValidatorType {
        return inputs[index]
    }
}

public extension InputHolder {
    public static func builder() -> Builder {
        return Builder()
    }
    
    /// Return inputDetails.
    public var inputs: [InputViewDetailValidatorType] {
        return allInputs
    }
    
    /// Get inputs as an Array of InputViewDetailType.
    public var inputDetails: [InputViewDetailType] {
        return inputs
    }
    
    /// Get inputs as an Array of InputViewDecoratorType.
    public var inputDecorators: [InputViewDecoratorType] {
        return inputs
    }
}

extension InputHolder: InputHolderType {}
