//
//  Copyright 2024, Jamf
//

// To parse the JSON, use the following:
//   let patchSoftwareTitleConfigurations = try? JSONDecoder().decode(PatchSoftwareTitleConfigurations.self, from: jsonData)


// MARK: - ApiIntegration
struct ApiIntegration: Codable {
    let id: String
    let displayName: String
    let enabled: Bool
    let accessTokenLifetimeSeconds: Int
    let appType: String
    let clientId: String
    let authorizationScopes: [String]
    
    init(id: String, displayName: String, enabled: Bool, accessTokenLifetimeSeconds: Int, appType: String, clientId: String, authorizationScopes: [String]) {
        self.id = id
        self.displayName = displayName
        self.enabled = enabled
        self.accessTokenLifetimeSeconds = accessTokenLifetimeSeconds
        self.appType = appType
        self.clientId = clientId
        self.authorizationScopes = authorizationScopes
    }
}

class ApiIntegrations {
    static var source = [ApiIntegration]()
    static var destination = [ApiIntegration]()
}

// MARK: - ApiRole
struct ApiRole: Codable {
    let id: String
    let displayName: String
    let privileges: [String]
    
    init(id: String, displayName: String, privileges: [String]) {
        self.id = id
        self.displayName = displayName
        self.privileges = privileges
    }
}

class ApiRoles {
    static var source = [ApiRole]()
    static var destination = [ApiRole]()
}

// MARK: - NamdId
struct NameId: Codable {
    let id: Int
    let name: String
    
    init(id: Int, name: String) {
        self.id   = id
        self.name = name
    }
}

//class ExternalPatchSource {
//    static var source = [NameId]()
//    static var destination = [NameId]()
//}

class PatchSource {
//    static var source = [NameId]()
    static var destination = [NameId]()
}

// MARK: - Category
struct Category: Codable {
    let id: String
    let name: String
    let priority: Int
    
    init(id: String, name: String, priority: Int) {
        self.id = id
        self.name = name
        self.priority = priority
    }
}

class Categories {
    static var source = [Category]()
    static var destination = [Category]()
}

// MARK: - Site
struct Site: Codable {
    let id: String
    let name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

class JamfProSites {
    static var source      = [Site]()
    static var destination = [Site]()
}

// MARK: - PatchSoftwareTitleConfiguration
struct PatchSoftwareTitleConfiguration: Codable {
    let id: String?
    let jamfOfficial: Bool
    let displayName, categoryId, siteId: String
    var categoryName, siteName: String?
    let uiNotifications, emailNotifications: Bool
    let softwareTitleId: String
    let extensionAttributes: [ExtensionAttribute]
    let softwareTitleName, softwareTitleNameId, softwareTitlePublisher, patchSourceName: String
    let patchSourceEnabled: Bool
    var packages: [PatchPackage]

    enum CodingKeys: String, CodingKey {
        case id, jamfOfficial, displayName, categoryId, categoryName, siteId, siteName
        case uiNotifications, emailNotifications, softwareTitleId
        case extensionAttributes, softwareTitleName, softwareTitleNameId
        case softwareTitlePublisher, patchSourceName, patchSourceEnabled, packages
    }
    
    init(id: String?, jamfOfficial: Bool, displayName: String, categoryId: String, categoryName: String?, siteId: String, siteName: String?, uiNotifications: Bool, emailNotifications: Bool, softwareTitleId: String, extensionAttributes: [ExtensionAttribute], softwareTitleName: String, softwareTitleNameId: String, softwareTitlePublisher: String, patchSourceName: String, patchSourceEnabled: Bool, packages: [PatchPackage]) {
        self.id = id
        self.jamfOfficial = jamfOfficial
        self.displayName = displayName
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.siteId = siteId
        self.siteName = siteName
        self.uiNotifications = uiNotifications
        self.emailNotifications = emailNotifications
        self.softwareTitleId = softwareTitleId
        self.extensionAttributes = extensionAttributes
        self.softwareTitleName = softwareTitleName
        self.softwareTitleNameId = softwareTitleNameId
        self.softwareTitlePublisher = softwareTitlePublisher
        self.patchSourceName = patchSourceName
        self.patchSourceEnabled = patchSourceEnabled
        self.packages = packages
    }
}

// MARK: - ExtensionAttribute
struct ExtensionAttribute: Codable {
    let accepted: Bool
    let eaId: String

    enum CodingKeys: String, CodingKey {
        case accepted
        case eaId
    }
}

struct ObjectAndDependency: Codable {
    let objectType: String
    let objectName: String
    let objectId: String
    
    enum CodingKeys: String, CodingKey {
        case objectType
        case objectName
        case objectId
    }
}
struct ObjectAndDependencies {
    static var records: [ObjectAndDependency] = []
}

// MARK: - PatchPackage
struct PatchPackage: Codable {
    let packageId, version: String
    var packageName, displayName: String?

    enum CodingKeys: String, CodingKey {
        case packageId
        case version, displayName, packageName
    }
    
    init(packageId: String, version: String, displayName: String?, packageName: String?) {
        self.packageId = packageId
        self.version = version
        self.displayName = displayName
        self.packageName = packageName
        
    }
}
class PatchPackages {
    static var source      = [PatchPackage]()
    static var destination = [PatchPackage]()
}

// MARK: - PatchPolicyDetails
struct PatchPolicyDetail: Codable {
    let id, name: String
    let enabled: Bool
    let targetPatchVersion, deploymentMethod, softwareTitleId, softwareTitleConfigurationId: String
    let killAppsDelayMinutes: Int
    let killAppsMessage: String
    let downgrade, patchUnknownVersion: Bool
    let notificationHeader: String
    let selfServiceEnforceDeadline: Bool
    let selfServiceDeadline: Int
    let installButtonText, selfServiceDescription, iconId: String
    let reminderFrequency: Int
    let reminderEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, enabled, targetPatchVersion, deploymentMethod
        case softwareTitleId
        case softwareTitleConfigurationId
        case killAppsDelayMinutes, killAppsMessage, downgrade, patchUnknownVersion, notificationHeader, selfServiceEnforceDeadline, selfServiceDeadline, installButtonText, selfServiceDescription
        case iconId
        case reminderFrequency, reminderEnabled
    }
}

class PatchPoliciesDetails {
    static var source      = [PatchPolicyDetail]()
    static var destination = [PatchPolicyDetail]()
}

typealias PatchSoftwareTitleConfigurations = [PatchSoftwareTitleConfiguration]
class PatchTitleConfigurations {
    static var source      = PatchSoftwareTitleConfigurations()
    static var destination = PatchSoftwareTitleConfigurations()
}

class SitePreferences {
    static var show = false
    static var modifierPrefixSuffix = userDefaults.string(forKey: "sitePrefixSuffix") ?? "Suffix"
    static var nameModifier = userDefaults.string(forKey: "siteNameModifier") ?? ""
    static var searches = userDefaults.string(forKey: "siteSearchesAction") ?? "Copy"
    static var policies = userDefaults.string(forKey: "sitePoliciesAction") ?? "Copy"
    static var profiles = userDefaults.string(forKey: "siteProfilesAction") ?? "Copy"
    static var apps = userDefaults.string(forKey: "siteAppsAction") ?? "Copy"
    static var patch = userDefaults.string(forKey: "sitePatchAction") ?? "Copy"
    static var groups = userDefaults.string(forKey: "siteGroupsAction") ?? "Copy"
    static var restricted = userDefaults.string(forKey: "siteRestrictedSoftware") ?? "Copy"
    static var classes = userDefaults.string(forKey: "siteClasses") ?? "Copy"
    static var ebooks = userDefaults.string(forKey: "siteEbooks") ?? "Copy"
    
}
