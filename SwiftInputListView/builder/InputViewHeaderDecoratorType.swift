//
//  InputViewHeaderDecoratorType.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/25/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import UIKit

/// Decorator class for input view headeer.
public protocol InputViewHeaderDecoratorType {
    
    /// Text color for header title.
    var headerTitleTextColor: UIColor? { get }
    
    /// Background color for header view.
    var backgroundColor: UIColor? { get }
}
