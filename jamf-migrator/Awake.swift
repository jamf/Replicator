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
var noSleepReturn: IOReturn?

public func disableSleep(reason: String) -> Bool? {
    guard noSleepReturn == nil else { return nil }
    noSleepReturn = IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleSystemSleep as CFString,IOPMAssertionLevel(kIOPMAssertionLevelOn), reason as CFString, &noSleepAssertionID)
    return noSleepReturn == kIOReturnSuccess
}

public func enableSleep() -> Bool {
    if noSleepReturn != nil {
        _ = IOPMAssertionRelease(noSleepAssertionID) == kIOReturnSuccess
        noSleepReturn = nil
        return true
    }
    return false
}
