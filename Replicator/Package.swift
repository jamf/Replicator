//
//  Copyright 2024, Jamf
//

import Foundation

struct Package: Codable, Identifiable {
    var id = UUID()
    var jamfProId: Int?
    var displayName: String
    var fileName: String
    var size: Int64?
    var category: String?
    var categoryId: String?
    var info: String?
    var notes: String?
    var priority: Int?
    var osRequirements: String?
    var fillUserTemplate: Bool?
    var indexed: Bool?     // Not to be updated
    var uninstall: Bool?   // Not to be updated
    var fillExistingUsers: Bool?
    var swu: Bool?
    var rebootRequired: Bool?
    var selfHealNotify: Bool?
    var selfHealingAction: String?
    var osInstall: Bool?
    var serialNumber: String?
    var parentPackageId: String?
    var basePath: String?
    var suppressUpdates: Bool?
    var cloudTransferStatus: String? // Not to be updated
    var ignoreConflicts: Bool?
    var suppressFromDock: Bool?
    var suppressEula: Bool?
    var suppressRegistration: Bool?
    var installLanguage: String?
    var osInstallerVersion: String?
    var manifest: String?
    var manifestFileName: String?
    var format: String?
    var install_if_reported_available: String?
    var reinstall_option: String?
    var send_notification: Bool?
    var switch_with_package: String?
    var triggering_files: [String: String]?

    init(jamfProId: Int?, displayName: String, fileName: String, category: String, size: Int64?) {
        self.jamfProId = jamfProId
        self.displayName = displayName
        self.fileName = fileName
        self.category = category
        self.size = size
    }

    /*
    init(capiPackageDetail: JsonCapiPackageDetail) {
        jamfProId = capiPackageDetail.id
        displayName = capiPackageDetail.name ?? ""
        fileName = capiPackageDetail.filename ?? ""
        category = capiPackageDetail.category ?? "None"
        let hashType = capiPackageDetail.hash_type ?? "MD5"
        let hashValue = capiPackageDetail.hash_value
//        if let hashValue, !hashValue.isEmpty {
//            checksums.updateChecksum(Checksum(type: ChecksumType.fromRawValue(hashType), value: hashValue))
//        }
        info = capiPackageDetail.info
        notes = capiPackageDetail.notes
        priority = capiPackageDetail.priority
        osRequirements = capiPackageDetail.os_requirements
        fillUserTemplate = capiPackageDetail.fill_user_template
        fillExistingUsers = capiPackageDetail.fill_existing_users
        rebootRequired = capiPackageDetail.reboot_required
        osInstallerVersion = capiPackageDetail.os_requirements
        install_if_reported_available = capiPackageDetail.install_if_reported_available
        reinstall_option = capiPackageDetail.reinstall_option
        send_notification = capiPackageDetail.send_notification
        switch_with_package = capiPackageDetail.switch_with_package
        triggering_files = capiPackageDetail.triggering_files
    }
     */


    init(uapiPackageDetail: JsonUapiPackageDetail) {
        if let jamfProIdString = uapiPackageDetail.id, let jamfProId = Int(jamfProIdString) {
            self.jamfProId = jamfProId
        }
        self.displayName = uapiPackageDetail.packageName ?? ""
        self.fileName = uapiPackageDetail.fileName ?? ""
        self.categoryId = uapiPackageDetail.categoryId ?? "-1"
//        if let md5Value = uapiPackageDetail.md5, !md5Value.isEmpty {
//             self.checksums.updateChecksum(Checksum(type: .MD5, value: md5Value))
//        }
//        if let sha256Value = uapiPackageDetail.sha256, !sha256Value.isEmpty {
//            self.checksums.updateChecksum(Checksum(type: .SHA_256, value: sha256Value))
//        }
//        if let hashType = uapiPackageDetail.hashType, !hashType.isEmpty, let hashValue = uapiPackageDetail.hashValue, !hashValue.isEmpty {
//            self.checksums.updateChecksum(Checksum(type: ChecksumType.fromRawValue(hashType), value: hashValue))
//        }
        if let sizeString = uapiPackageDetail.size {
            self.size = Int64(sizeString)
        }
        self.info                 = uapiPackageDetail.info
        self.notes                = uapiPackageDetail.notes
        self.priority             = uapiPackageDetail.priority
        self.osRequirements       = uapiPackageDetail.osRequirements
        self.fillUserTemplate     = uapiPackageDetail.fillUserTemplate
        self.indexed              = uapiPackageDetail.indexed
        self.uninstall            = uapiPackageDetail.uninstall
        self.fillExistingUsers    = uapiPackageDetail.fillExistingUsers
        self.swu                  = uapiPackageDetail.swu
        self.rebootRequired       = uapiPackageDetail.rebootRequired
        self.selfHealNotify       = uapiPackageDetail.selfHealNotify
        self.selfHealingAction    = uapiPackageDetail.selfHealingAction
        self.osInstall            = uapiPackageDetail.osInstall
        self.serialNumber         = uapiPackageDetail.serialNumber
        self.parentPackageId      = uapiPackageDetail.parentPackageId
        self.basePath             = uapiPackageDetail.basePath
        self.suppressUpdates      = uapiPackageDetail.suppressUpdates
        self.cloudTransferStatus  = uapiPackageDetail.cloudTransferStatus
        self.ignoreConflicts      = uapiPackageDetail.ignoreConflicts
        self.suppressFromDock     = uapiPackageDetail.suppressFromDock
        self.suppressEula         = uapiPackageDetail.suppressEula
        self.suppressRegistration = uapiPackageDetail.suppressRegistration
        self.installLanguage      = uapiPackageDetail.installLanguage
        self.osInstallerVersion   = uapiPackageDetail.osInstallerVersion
        self.manifest             = uapiPackageDetail.manifest
        self.manifestFileName     = uapiPackageDetail.manifestFileName
        self.format               = uapiPackageDetail.format
    }
}

