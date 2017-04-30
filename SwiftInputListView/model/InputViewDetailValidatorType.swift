//
//  InputViewDetailValidatorType.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/24/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftBaseViews
import SwiftInputView
import SwiftUtilities

/// This protocol extends from InputValidatorType, InputViewDetailType and
/// InputViewDecoratorType.
///
/// It can be used both for view building and input validation.
public protocol InputViewDetailValidatorType:
    InputViewDetailType,
    InputValidatorType,
    SectionableListItemType {}
