//
//  InputViewDetailValidatorType.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/24/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftInputView
import SwiftUtilities

/// This protocol extends from InputValidatorType, InputViewDetailType and
/// InputViewDecoratorType.
///
/// It can be used both for view building and input validation.
public protocol InputViewDetailValidatorType:
    InputViewDetailType,
    InputValidatorType {
    
    /// Each input may belong to a section. If there is only one section
    /// for all inputs, ignore.
    var section: InputSectionType { get }
}
