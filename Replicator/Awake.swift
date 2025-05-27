//
//  Awake.swift
//  Replicator
//
//  Created by Leslie Helou on 10/22/22.
//  Copyright 2024 Jamf. All rights reserved.
//

import Foundation
import IOKit.pwr_mgt

var noSleepAssertionID: IOPMAssertionID = 0
var noSleepReturn: IOReturn?

public func disableSleep(reason: String) -> Bool? {
    logFunctionCall()
    guard noSleepReturn == nil else { return nil }
    noSleepReturn = IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleSystemSleep as CFString,IOPMAssertionLevel(kIOPMAssertionLevelOn), reason as CFString, &noSleepAssertionID)
    return noSleepReturn == kIOReturnSuccess
}

public func enableSleep() -> Bool {
    logFunctionCall()
    if noSleepReturn != nil {
        _ = IOPMAssertionRelease(noSleepAssertionID) == kIOReturnSuccess
        noSleepReturn = nil
        return true
    }
    return false
}
