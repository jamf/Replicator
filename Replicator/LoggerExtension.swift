//
//  LoggerExtension
//

// log stream --info --predicate 'subsystem == "com.jamf.jamf-migrator"'
// log stream --debug --predicate 'subsystem == "com.jamf.jamf-migrator" AND category == "function"' | tee -a ~/Desktop/replicator_functions.txt
// cat ~/Desktop/replicator_functions.txt | awk '{for (i=11; i<=NF; i++) printf $i " "; print ""}' | tee -a ~/Desktop/replicator_functions1.txt

import Foundation
import OSLog

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
    static let function                      = Logger(subsystem: subsystem, category: "function")
}

func logFunctionCall(file: String = #file, function: String = #function, line: Int = #line) {
    let fileName = (file as NSString).lastPathComponent
    Logger.function.debug("called \(fileName.replacingOccurrences(of: ".swift", with: ""), privacy: .public).\(function, privacy: .public) [line: \(line, privacy: .public)]")
}
