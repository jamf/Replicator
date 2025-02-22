//
//  LoggerExtension
//

import Foundation
import os.log

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    
    static let writeToLog                    = Logger(subsystem: subsystem, category: "writeToLog")
    static let token                         = Logger(subsystem: subsystem, category: "token")
    static let cleanup_json                  = Logger(subsystem: subsystem, category: "cleanup_json")
    static let cleanup_xml                   = Logger(subsystem: subsystem, category: "cleanup_xml")
    static let createEndpoints_queue         = Logger(subsystem: subsystem, category: "createEndpoints_queue")
    static let createEndpoints_capi          = Logger(subsystem: subsystem, category: "createEndpoints_capi")
    static let createEndpoints_jpapi         = Logger(subsystem: subsystem, category: "createEndpoints_jpapi")
    static let endpointXml_endPointByIdQueue = Logger(subsystem: subsystem, category: "endpointXml_endPointByIdQueue")
    static let endpointXml_getById           = Logger(subsystem: subsystem, category: "endpointXml_getById")
    static let existingObjects_capi          = Logger(subsystem: subsystem, category: "existingObjects_capi")
    static let exportItem_export             = Logger(subsystem: subsystem, category: "exportItem_export")
    static let iconDelegate_icons            = Logger(subsystem: subsystem, category: "iconDelegate_icons")
    static let iconDelegate_iconMigrate      = Logger(subsystem: subsystem, category: "iconDelegate_iconMigrate")
    static let ObjectDelegate_getAll         = Logger(subsystem: subsystem, category: "ObjectDelegate_getAll")
    static let headless_runComplete          = Logger(subsystem: subsystem, category: "headless_runComplete")
}
