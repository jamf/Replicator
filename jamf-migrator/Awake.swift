//
//  Awake.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 10/22/22.
//  Copyright © 2022 jamf. All rights reserved.
//

import Foundation
import IOKit.pwr_mgt

var noSleepAssertionID: IOPMAssertionID = 0
var noSleepReturn: IOReturn? // Could probably be replaced by a boolean value, for example 'isBlockingSleep', just make sure 'IOPMAssertionRelease' doesn't get called, if 'IOPMAssertionCreateWithName' failed.
var noSleepReturn2: IOReturn?

//public func disableScreenSleep(reason: String) -> Bool? {
//    guard noSleepReturn == nil else { return nil }
//    noSleepReturn = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
//                                            IOPMAssertionLevel(kIOPMAssertionLevelOn),
//                                            reason as CFString,
//                                            &noSleepAssertionID)
//}

public func disableSleep(reason: String) -> Bool? {
    guard noSleepReturn2 == nil else { return nil }
    noSleepReturn2 = IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleSystemSleep as CFString,IOPMAssertionLevel(kIOPMAssertionLevelOn), reason as CFString, &noSleepAssertionID)
    return noSleepReturn == kIOReturnSuccess
}

//public func enableScreenSleep() -> Bool {
//    if noSleepReturn != nil {
//        _ = IOPMAssertionRelease(noSleepAssertionID) == kIOReturnSuccess
//        noSleepReturn = nil
//        return true
//    }
//    return false
//}
public func enableSleep() -> Bool {
    if noSleepReturn != nil {
        _ = IOPMAssertionRelease(noSleepAssertionID) == kIOReturnSuccess
        noSleepReturn = nil
        return true
    }
    return false
}
