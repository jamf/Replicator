//
//  Globals.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 11/29/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Foundation

struct History {
    static var logPath: String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
    static var logFile = ""
}

struct LogLevel {
    static var debug = false
}
