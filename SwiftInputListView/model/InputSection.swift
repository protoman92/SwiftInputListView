//
//  InputSection.swift
//  TestApplication
//
//  Created by Hai Pham on 4/25/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftUtilities
import UIKit

/// Implement this protocol to provide section information.
public protocol InputSectionType {
    
    /// Since we are not using Hashable for this protocol, we can use String
    /// values as keys.
    var identifier: String { get }
}

/// Implement this protocol to provide input section and holders.
public protocol InputSectionHolderType {
    
    /// Get the associated InputSectionType.
    var inputSection: InputSectionType { get }
    
    /// Get the associated Array of InputHolder.
    var inputHolders: [InputHolderType] { get }
    
    init(with section: InputSectionType)
}

/// Each instance of this struct represents a section for 
/// UIAdapterInputListView.
public struct InputSectionHolder {
    fileprivate var section: InputSectionType
    fileprivate var holders: [InputHolderType]
    
    public init(with section: InputSectionType) {
        self.section = section
        holders = []
    }
    
    /// Builder class for InputSection.
    public final class Builder {
        fileprivate var section: InputSectionHolder
        
        fileprivate init(with section: InputSectionType) {
            self.section = InputSectionHolder(with: section)
        }
        
        /// Append an InputHolderType.
        ///
        /// - Parameters:
        ///   - holder: An InputHolderType instance.
        ///   - section: An InputSectionType instance.
        /// - Returns: The current Builder instance.
        public func add(holder: InputHolderType) -> Builder {
            section.holders.append(holder)
            return self
        }
        
        /// Append a Sequence of InputHolderType.
        ///
        /// - Parameter holders: A Sequence of InputHolderType.
        /// - Returns: The current Builder instance.
        public func add<S: Sequence>(holders: S) -> Builder
            where S.Iterator.Element: InputHolderType
        {
            return add(holders: holders.map(eq))
        }
        
        /// Append a Sequence of InputHolderType.
        ///
        /// - Parameter holders: A Sequence of InputHolderType.
        /// - Returns: The current Builder instance.
        public func add<S: Sequence>(holders: S) -> Builder
            where S.Iterator.Element == InputHolderType
        {
            section.holders.append(contentsOf: holders)
            return self
        }
        
        /// Set holders.
        ///
        /// - Parameter holders: A Sequence of InputHolderType.
        /// - Returns: The current Builder instance.
        public func with<S: Sequence>(holders: S) -> Builder
            where S.Iterator.Element: InputHolderType
        {
            return with(holders: holders.map(eq))
        }
        
        /// Set holders.
        ///
        /// - Parameter holders: A Sequence of InputHolderType.
        /// - Returns: The current Builder instance.
        public func with<S: Sequence>(holders: S) -> Builder
            where S.Iterator.Element == InputHolderType
        {
            section.holders = holders.map(eq)
            return self
        }
        
        public func build() -> InputSectionHolder {
            return section
        }
    }
}

extension InputSectionHolder: CustomComparisonType {
    public func equals(object: InputSectionHolder?) -> Bool {
        return section.identifier == object?.section.identifier
    }
}

extension InputSectionHolder: InputSectionHolderType {
    
    /// Return section.
    public var inputSection: InputSectionType {
        return section
    }
    
    /// Return holders.
    public var inputHolders: [InputHolderType] {
        return holders
    }
}

public extension InputSectionHolder {
    
    /// Get a Builder instance.
    ///
    /// - Returns: A Builder instance.
    public static func builder(with section: InputSectionType) -> Builder {
        return Builder(with: section)
    }
}
