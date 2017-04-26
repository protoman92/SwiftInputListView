//
//  InputViewHeaderBuilder.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/25/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftUtilities
import SwiftUIUtilities

/// Implement this protocol to provide builder for input view header.
public protocol InputViewHeaderBuilderType: ViewBuilderType {
    init(with section: InputSectionType)
    
    /// Get the associated input section.
    var inputSection: InputSectionType { get }
}

/// Builder class for input view header.
open class InputViewHeaderBuilder {
    fileprivate let section: InputSectionType
    
    public required init(with section: InputSectionType) {
        self.section = section
    }
    
    public func builderComponents(for view: UIView) -> [ViewBuilderComponentType] {
        let section = self.section
        let headerTitle = self.headerTitle(for: view, using: section)
        return [headerTitle]
    }
    
    /// Header title for each section.
    ///
    /// - Parameters:
    ///   - view: The master UIView.
    ///   - section: An InputSectionType instance.
    /// - Returns: A ViewBuilderComponentType instance.
    open func headerTitle(for view: UIView, using section: InputSectionType)
        -> ViewBuilderComponentType
    {
        let label = UIBaseLabel()
        label.fontName = String(describing: 1)
        label.fontSize = String(describing: 5)
        label.accessibilityIdentifier = headerTitleId
        label.text = section.header
        
        let constraints = FitConstraintSet
            .fit(forParent: view, andChild: label)
            .constraints
        
        return ViewBuilderComponent.builder()
            .with(view: label)
            .with(constraints: constraints)
            .build()
    }
}

extension InputViewHeaderBuilder: InputViewHeaderBuilderType {
    
    /// Return section.
    public var inputSection: InputSectionType {
        return section
    }
}

extension InputViewHeaderBuilder: InputViewHeaderIdentifierType {}
