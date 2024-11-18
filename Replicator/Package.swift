//
//  Copyright 2024, Jamf
//

import Foundation

struct Package: Identifiable {
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
        info                 = uapiPackageDetail.info
        notes                = uapiPackageDetail.notes
        priority             = uapiPackageDetail.priority
        osRequirements       = uapiPackageDetail.osRequirements
        fillUserTemplate     = uapiPackageDetail.fillUserTemplate
        indexed              = uapiPackageDetail.indexed
        uninstall            = uapiPackageDetail.uninstall
        fillExistingUsers    = uapiPackageDetail.fillExistingUsers
        swu                  = uapiPackageDetail.swu
        rebootRequired       = uapiPackageDetail.rebootRequired
        selfHealNotify       = uapiPackageDetail.selfHealNotify
        selfHealingAction    = uapiPackageDetail.selfHealingAction
        osInstall            = uapiPackageDetail.osInstall
        serialNumber         = uapiPackageDetail.serialNumber
        parentPackageId      = uapiPackageDetail.parentPackageId
        basePath             = uapiPackageDetail.basePath
        suppressUpdates      = uapiPackageDetail.suppressUpdates
        cloudTransferStatus  = uapiPackageDetail.cloudTransferStatus
        ignoreConflicts      = uapiPackageDetail.ignoreConflicts
        suppressFromDock     = uapiPackageDetail.suppressFromDock
        suppressEula         = uapiPackageDetail.suppressEula
        suppressRegistration = uapiPackageDetail.suppressRegistration
        installLanguage      = uapiPackageDetail.installLanguage
        osInstallerVersion   = uapiPackageDetail.osInstallerVersion
        manifest             = uapiPackageDetail.manifest
        manifestFileName     = uapiPackageDetail.manifestFileName
        format               = uapiPackageDetail.format
    }
}
