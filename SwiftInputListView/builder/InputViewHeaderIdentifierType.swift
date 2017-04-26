//
//  InputViewHeaderIdentifierType.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/25/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

/// Implement this protocol to access view accessibilityIdenfitier.
public protocol InputViewHeaderIdentifierType {}

public extension InputViewHeaderIdentifierType {
    
    /// Accessibility identifier for header title.
    public var headerTitleId: String {
        return "headerTitle"
    }
}
