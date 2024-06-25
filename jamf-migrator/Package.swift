//
//  Package.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 4/23/24.
//  Copyright © 2024 jamf. All rights reserved.
//

import Foundation

struct AllPackages: Codable {
    let totalCount: Int
    let results: [Package]
}

struct Package: Codable {
    let id, packageName, fileName: String?
    let categoryID, parentPackageID, size: String?
    let info, notes: String?
    let priority: Int?
    let osRequirements: String?
    let fillUserTemplate, indexed, fillExistingUsers, swu: Bool?
    let rebootRequired, selfHealNotify: Bool?
    let selfHealingAction: String?
    let osInstall: Bool?
    let serialNumber: String?
    let basePath: String?
    let suppressUpdates: Bool?
    let cloudTransferStatus: String?
    let ignoreConflicts, suppressFromDock, suppressEULA, suppressRegistration: Bool?
    let installLanguage: String?
    let md5: String?
    let sha256: String?
    let hashType: String?
    let hashValue: String?
    let osInstallerVersion: String?
    let manifest: String?
    let manifestFileName: String?
    let format: String?

    enum CodingKeys: String, CodingKey {
        case id, packageName, fileName, size
        case categoryID = "categoryId"
        case info, notes
        case parentPackageID = "parentPackageId"
        case priority, osRequirements, fillUserTemplate, indexed, fillExistingUsers, swu, rebootRequired, selfHealNotify, selfHealingAction, osInstall, serialNumber
        case basePath, suppressUpdates, cloudTransferStatus, ignoreConflicts, suppressFromDock
        case suppressEULA = "suppressEula"
        case suppressRegistration, installLanguage, md5, sha256, hashType, hashValue, osInstallerVersion, manifest, manifestFileName, format
    }
}
