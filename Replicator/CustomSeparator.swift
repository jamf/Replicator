//
//  CustomSeparator.swift
//  Replicator
//
//  Created by Leslie Helou on 10/15/22.
//  Copyright 2024 Jamf. All rights reserved.
//

import Foundation
import AppKit

class CustomSeparator: NSSplitView {
    // override
    override var dividerThickness:CGFloat {
        get {
            return 0.0
        }
    }
//    override var dividerColor: NSColor {
//        get {
//            return appColor.highlight["classic"]!
//        }
//    }
}
