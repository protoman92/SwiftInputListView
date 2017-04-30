//
//  MockInput.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/26/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftBaseViews
import SwiftInputView
import SwiftUtilities
import SwiftUIUtilities

public enum InputDetail {
    case title
    case firstName
    case lastName
    case phoneExtension
    case phoneNumber
    case email
    case password
    case confirmPassword
    case description
    
    public static var allValues: [InputDetail] {
        return [
            title,
            firstName,
            lastName,
            phoneExtension,
            phoneNumber,
            email,
            password,
            confirmPassword,
            description
        ]
    }
}

extension InputDetail: InputViewDetailType {
    public var identifier: String { return String(describing: self) }
    public var isRequired: Bool { return true }
    
    public var decorator: InputViewDecoratorType {
        return InputViewDecorator(for: self)
    }
    
    public var inputType: InputType {
        switch self {
        case .description:
            return TextInput.description
            
        case .password, .confirmPassword:
            return TextInput.password
            
        default:
            return TextInput.default
        }
    }
    
    public var placeholder: String? {
        switch self {
        case .title:
            return "Title"
            
        case .firstName:
            return "First name"
            
        case .lastName:
            return "Last name"
            
        case .password:
            return "Password"
            
        case .confirmPassword:
            return "Confirm password"
            
        case .email:
            return "Email"
            
        case .description:
            return "About yourself"
            
        case .phoneExtension:
            return "Ext"
            
        case .phoneNumber:
            return "Phone number"
        }
    }
    
    public var shouldDisplayRequiredIndicator: Bool {
        switch self {
        case .title, .phoneExtension:
            return false
            
        default:
            return true
        }
    }
    
    public var inputWidth: CGFloat? {
        switch self {
        case .title, .phoneExtension:
            return Size.larger.value ?? 0
            
        default:
            return 0
        }
    }
    
    public var inputHeight: CGFloat? { return nil }
    
    public var viewBuilderComponentType: InputViewBuilderComponentType.Type? {
        return nil
    }
}

public extension InputDetail {
    public static var inputs = [
        [InputDetail.title, .firstName, .lastName],
        [InputDetail.password],
        [InputDetail.confirmPassword],
        [InputDetail.email],
        [InputDetail.phoneExtension, .phoneNumber],
        [InputDetail.description]
    ]
    
    public static var inputHolders = InputDetail.inputs.map({
        InputHolder.builder().with(items: $0).build()
    })
    
    public static var randomInputs: [[InputViewDetailValidatorType]] {
        let count = self.inputs.count
        let elementCount = Int.random(0, count)
        return self.inputs.randomize(elementCount)
    }
    
    public static var randomInputHolders: [InputHolder] {
        let count = self.inputHolders.count
        let elementCount = Int.random(0, count)
        return self.inputHolders.randomize(elementCount)
    }
    
    public static var randomInputSectionHolders: [InputSectionHolder] {
        return self.randomInputHolders.sectionHolders
    }
}

extension InputDetail: InputValidatorType {
    public func validate<S: Sequence>(input: InputDataType, against inputs: S)
        throws where S.Iterator.Element: InputDataType
    {
        let content = input.inputContent
        
        switch self {
        case .title:
            if !(["Mr", "Mrs", "Ms"].contains(content)) {
                throw Exception("Invalid title")
            }
            
        case .email:
            if !content.isEmail {
                throw Exception("Not an email")
            }
            
        case .password:
            if content.characters.count < 8 {
                throw Exception("Password too short")
            }
            
        case .confirmPassword:
            guard
                let password = inputs.filter({
                    $0.inputIdentifier == InputDetail.password.identifier
                }).first?.inputContent,
                content == password
            else {
                throw Exception("Passwords do not match")
            }
            
        default:
            break
        }
    }
}

class InputViewDecorator: TextInputViewDecoratorType {
    fileprivate let input: InputViewDetailValidatorType
    
    public init(for input: InputViewDetailValidatorType) {
        self.input = input
    }
    
    public var inputBackgroundColor: UIColor { return .gray }
    public var inputCornerRadius: CGFloat { return 5 }
    public var inputTextColor: UIColor { return .white }
    public var inputTintColor: UIColor { return .white }
    public var inputTextAlignment: NSTextAlignment { return .natural }
    public var requiredIndicatorTextColor: UIColor { return .white }
    public var requiredIndicatorText: String { return "*R" }
    public var placeholderTextColor: UIColor { return .lightGray }
}

extension InputDetail: InputViewDetailValidatorType {
    public var section: ListSectionType? {
        switch self {
        case .firstName, .lastName, .title, .description:
            return InputSection.personalInformation
            
        case .phoneExtension, .phoneNumber, .email:
            return InputSection.contactInformation
            
        case .password, .confirmPassword:
            return InputSection.accountInformation
        }
    }
}

public extension Sequence where
    Iterator.Element: ListItemHolderType,
    Iterator.Element.Item == InputViewDetailValidatorType
{
    /// Get an Array of ListSectionHolderType, based on each
    /// SectionableListItemType section.
    public var sectionHolders: [InputSectionHolder] {
        var sectionHolders = [InputSectionHolder]()
        let sections = self.flatMap({$0.section})
        
        for section in sections {
            // There might be duplicate sections, so we skip if a section
            // has already been added.
            guard !sectionHolders.contains(where: {
                $0.section?.identifier == section.identifier
            }) else {
                continue
            }
            
            let holders = filter({$0.section?.identifier == section.identifier})
                .map({$0.items})
                .map({InputHolder.builder().with(items: $0).build()})
            
            let sectionHolder = InputSectionHolder.builder()
                .with(items: holders)
                .with(section: section)
                .build()
            
            sectionHolders.append(sectionHolder)
        }
        
        return sectionHolders
    }
}
