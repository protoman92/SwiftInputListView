//
//  UIControlTestUtil.swift
//  SwiftInputListView
//
//  Created by Hai Pham on 4/26/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import UIKit
import SwiftUtilities
import SwiftUtilitiesTests

extension UIControl {
    open override class func initialize() {
        guard self === UIControl.self else {
            return
        }
        
        once(using: NSUUID().uuidString) {
            let oSelector = #selector(self.sendAction(_:to:for:))
            let sSelector = #selector(self.ssa(_:to:for:))
            let oMethod = class_getInstanceMethod(self, oSelector)
            let sMethod = class_getInstanceMethod(self, sSelector)
            
            let didAddMethod = class_addMethod(self, oSelector,
                                               method_getImplementation(sMethod),
                                               method_getTypeEncoding(sMethod))
            
            if didAddMethod {
                class_replaceMethod(self,
                                    sSelector,
                                    method_getImplementation(oMethod),
                                    method_getTypeEncoding(oMethod))
            } else {
                method_exchangeImplementations(oMethod, sMethod)
            }
        }
    }

    func ssa(_ action: Selector, to target: AnyObject?, for event: UIEvent?) {
        print("Sending action to \(target)")
        _ = target?.perform(action, with: self)
    }
}
