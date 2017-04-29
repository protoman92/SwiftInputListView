//
//  InputViewHeaderBuilderConfig.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/25/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftUtilities
import SwiftUIUtilities

/// Implement this protocol to provide configurations for input view header.
public protocol InputViewHeaderConfigType: ViewBuilderConfigType {
    init(with decorator: InputViewHeaderDecoratorType)
}

/// Builder configuration class for input view header.
open class InputViewHeaderBuilderConfig {
    fileprivate let decorator: InputViewHeaderDecoratorType
    
    public required init(with decorator: InputViewHeaderDecoratorType) {
        self.decorator = decorator
    }
    
    public func configure(for view: UIView) {
        view.backgroundColor = backgroundColor
        
        if let headerTitle = view.subviews.filter({
            $0.accessibilityIdentifier == headerTitleId
        }).first as? UILabel {
            configure(headerTitle: headerTitle)
        }
    }
    
    open func configure(headerTitle: UILabel) {
        headerTitle.textColor = headerTitleTextColor
    }
}

extension InputViewHeaderBuilderConfig: InputViewHeaderConfigType {}
extension InputViewHeaderBuilderConfig: InputViewHeaderIdentifierType {}

extension InputViewHeaderBuilderConfig: InputViewHeaderDecoratorType {
    public var headerTitleTextColor: UIColor {
        return decorator.headerTitleTextColor ?? .darkGray
    }
    
    public var backgroundColor: UIColor {
        return decorator.backgroundColor ?? .clear
    }
}
