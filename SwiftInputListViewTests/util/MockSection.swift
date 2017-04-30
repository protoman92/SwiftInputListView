//
//  MockSection.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/26/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftBaseViews
import SwiftInputView

public enum InputSection: String {
    case personalInformation
    case contactInformation
    case accountInformation
}

extension InputSection: ListSectionType {
    public var viewBuilderType: ListHeaderBuilderType.Type? { return nil }
    public var identifier: String { return rawValue }
    
    public var header: String {
        switch self {
        case .personalInformation:
            return "Personal information"
            
        case .contactInformation:
            return "Contact information"
            
        case .accountInformation:
            return "Account information"
        }
    }
    
    public var decorator: ListHeaderDecoratorType {
        return InputHeaderDecorator(section: self)
    }
}

public extension InputSection {
    var headerTitleTextColor: UIColor? { return nil }
    var backgroundColor: UIColor? { return nil }
}

public class InputHeaderDecorator: ListHeaderDecoratorType {
    public init(section: ListSectionType) {}
}
