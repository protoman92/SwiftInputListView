//
//  InputHolder.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/24/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftBaseViews
import SwiftInputView
import SwiftUIUtilities
import SwiftUtilities

/// Use this typealias to avoid too many generics.
public typealias InputHolder = ListItemHolder<InputViewDetailValidatorType>

public extension ListItemHolderType where Item == InputViewDetailValidatorType {
    
    /// We can simply return items here and it will be correctly cast.
    public var inputDetails: [InputViewDetailType] { return items }
    
    /// Get the associated decorators.
    public var inputDecorators: [InputViewDecoratorType] {
        return items.map({$0.decorator})
    }
    
    /// Get the largest height, based on all stored InputViewDetailType.
    public var largestHeight: CGFloat { return inputDetails.largestHeight }
    
    public var section: ListSectionType? { return items.first?.section }
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
                $0.section.identifier == section.identifier
            }) else {
                continue
            }
            
            let holders = filter({$0.section?.identifier == section.identifier})
                .map({$0.items})
                .map({InputHolder.builder().with(items: $0).build()})
            
            let sectionHolder = InputSectionHolder
                .builder(with: section)
                .with(items: holders)
                .build()
            
            sectionHolders.append(sectionHolder)
        }
        
        return sectionHolders
    }
}
