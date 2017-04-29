//
//  InputListViewDecoratorType.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/25/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import UIKit

/// Implement this protocol to provide configurations for 
/// UIAdaptableInputListView appearance.
@objc public protocol InputListViewDecoratorType {
    
    /// This value will be used to separate consecutive cells.
    @objc optional var itemSpacing: CGFloat { get }
    
    /// This value will be used to separate consecutive sections.
    @objc optional var sectionSpacing: CGFloat { get }
    
    /// This value will be used to resize the header view.
    @objc optional var sectionHeight: CGFloat { get }
}
