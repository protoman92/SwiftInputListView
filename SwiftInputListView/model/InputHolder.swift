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
        return inputDetails.flatMap({$0.decorator.inputViewHeight}).max() ?? 0
    }
    
    /// Get the associated section for all InputViewDetailValidatorType
    /// instances. If there are different sections among the inputs, take
    /// only the first one i.e. we are assuming all inputs share the same
    /// section (as it should be).
    public var section: InputSectionType? {
        return inputs.first?.section
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
        return inputs.map({$0.decorator})
    }
}

extension InputHolder: InputHolderType {}

public extension Sequence where Iterator.Element == InputHolderType {
    
    /// Get an Array of InputSectionHolderType, based on each InputHolderType's
    /// inputSection.
    public var inputSectionHolders: [InputSectionHolderType] {
        var sectionHolders = [InputSectionHolderType]()
        let sections = self.flatMap({$0.section})
        
        for section in sections {
            // There might be duplicate sections, so we skip if a section
            // has already been added.
            guard !sectionHolders.contains(where: {
                $0.inputSection.identifier == section.identifier
            }) else {
                continue
            }
            
            let holders = filter({
                $0.section?.identifier == section.identifier
            })
            
            let sectionHolder = InputSectionHolder
                .builder(with: section)
                .with(holders: holders)
                .build()
            
            sectionHolders.append(sectionHolder)
        }
        
        return sectionHolders
    }
}

public extension Sequence where Iterator.Element: InputHolderType {
    
    /// Same as above, but we need to map each instance to an InputHolderType
    /// first.
    public var inputSectionHolders: [InputSectionHolderType] {
        return self.map({$0 as InputHolderType}).inputSectionHolders
    }
}
