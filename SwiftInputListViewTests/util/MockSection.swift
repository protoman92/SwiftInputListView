//
//  MockSection.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/26/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftInputView

public enum InputSection: String {
    case personalInformation
    case contactInformation
    case accountInformation
}

extension InputSection: InputSectionType {
    public var viewBuilderType: InputViewHeaderBuilderType.Type? { return nil }
    public var viewConfigType: InputViewHeaderConfigType.Type? { return nil }
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
}

public extension InputSection {
    var headerTitleTextColor: UIColor? { return nil }
    var backgroundColor: UIColor? { return nil }
}

public struct InputListViewDecorator: InputListViewDecoratorType {
    public var sectionHeight: CGFloat? { return nil }
    public var sectionSpacing: CGFloat? { return nil }
    public var itemSpacing: CGFloat? { return nil }
    
    public init() {}
}
