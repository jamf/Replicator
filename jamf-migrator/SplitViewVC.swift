//
//  SplitViewVC.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 10/15/22.
//  Copyright © 2022 jamf. All rights reserved.
//

import Foundation
import AppKit

//class SplitViewVC: NSSplitViewController {
////    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
////        print("dividerIndex: \(dividerIndex)")
////        print("proposedEffectiveRect: \(proposedEffectiveRect)")
//////        let thick = CustomThickness().dividerThickness
////
////        print("return empty rect")
////        return CGRect(x:proposedEffectiveRect.minX, y:proposedEffectiveRect.minY, width: 0, height: 0)
////    }
////
////    override func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
////        print("hide divider \(dividerIndex)")
////        let thick = self.splitView.dividerThickness
////        print("divider thickness \(thick)")
////        return true
////    }
//    override func viewWillAppear() {
//        print("[SplitViewVC] viewDidAppear")
//    }
//}
class CustomThickness: NSSplitView {
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
