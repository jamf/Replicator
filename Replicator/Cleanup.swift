//
//  Cleanup.swift
//  Replicator
//
//  Created by leslie on 11/30/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import Foundation
import os.log

class Cleanup: NSObject {
    
    static let shared = Cleanup()
    
    var updateUiDelegate: UpdateUiDelegate?
    let parser = XmlTagParser()
    
    func Json(endpoint: String, JSON: [String: Any], endpointID: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: String, destEpName: String, completion: @escaping (_ cleanJSON: String) -> Void) {
        logFunctionCall()
        
        Logger.cleanup_json.debug("enter cleanJSON - \(endpoint, privacy: .public)")
        
        var theEndpoint = endpoint
        
        switch endpoint {
        case "accounts/userid":
            theEndpoint = "jamfusers"
        case "accounts/groupid":
            theEndpoint = "jamfgroups"
        default:
            theEndpoint = endpoint
        }
        var JSONData = JSON
        
        switch endpoint {
        case "patch-software-title-configurations":
            JSONData["id"] = nil
            // adjust ids to destination server
//            for c in Categories.destination {
//                if c.name == JSONData["categoryName"] as! String {
//                    print("[cleanJSON - patchmanagement]     match categoryName: \(c.name), id: \(c.id)")
//                }
//            }
            if let categoryName = JSONData["categoryName"] as? String {
                JSONData["categoryId"] = Categories.destination.first(where: { $0.name == categoryName })?.id
            } else {
                JSONData["categoryId"] = "-1"
            }
            
            JSONData["categoryId"] = Categories.destination.first(where: { $0.name == JSONData["categoryName"] as? String })?.id ?? "-1"
            JSONData["categoryName"] = nil
            JSONData["siteId"] = JamfProSites.destination.first(where: { $0.name == JSONData["siteName"] as? String })?.id ?? "-1"

            JSONData["siteName"] = nil
            let patchPackages = JSONData["packages"] as? [[String: Any]]
            var updatedPackages: [[String: String]] = []
            for thePackage in patchPackages ?? [] {
                // get source package (file) name
                let sourcePackageName = (fileImport) ? thePackage["packageName"] as? String ?? "unknown package": PatchPackages.source.first(where: { $0.packageId == thePackage["packageId"] as? String })?.packageName ?? ""
                let packageId = PatchPackages.destination.first(where: { $0.packageName == sourcePackageName })?.packageId ?? ""
                
                if packageId.isEmpty {
                    WriteToLog.shared.message("Unable to locate patch package \(sourcePackageName) on the destination server.")
                } else {
                    updatedPackages.append(["packageId": packageId, "version": "\(thePackage["version"] ?? "")"])
                }
            }
            JSONData["packages"] = updatedPackages
            
        default:
            if action != "skip" {
                JSONData["id"] = nil
                
                for (key, value) in JSONData {
                    if "\(value)" == "<null>" {
                        JSONData[key] = nil
                    } else {
                        JSONData[key] = value
                    }
                }
            }
        }
        
        // migrating to another site
        if JamfProServer.toSite && !JamfProServer.destSite.isEmpty {
            if let siteId = JamfProSites.destination.first(where: { $0.name == JamfProServer.destSite })?.id {
                JSONData["siteId"] = siteId
            } else {
                WriteToLog.shared.message("Error updating site for patch management title \(JSONData["displayName"] as? String ?? "unknown").  Site \(JamfProServer.destSite) not found.")
            }
            if sitePref == "Copy" {
                if let objectName = JSONData["displayName"] as? String {
                    JSONData["displayName"] = "\(objectName) - \(JamfProServer.destSite)"
                } else {
                    WriteToLog.shared.message("Error updating site for patch management id \(endpointID). Problem determining displayName of object.")
                }
            }
        }
        
        CreateEndpoints.shared.jpapi(endpointType: theEndpoint, endPointJSON: JSONData, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: endpointID, destEpId: destEpId, ssIconName: "", ssIconId: "", ssIconUri: "", retry: false) {
            (result: String) in
            if LogLevel.debug { WriteToLog.shared.message("[endPointByID] \(result)") }
            if endpointCurrent == endpointCount {
                completion("last")
            } else {
                completion("")
            }
        }
    }
    
    func Xml(endpoint: String, Xml: String, endpointID: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: String, destEpName: String, completion: @escaping (_ result: String) -> Void) {
        logFunctionCall()
        
        Logger.cleanup_xml.debug("enter cleanXML - \(endpoint, privacy: .public)")
        
        if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] enter") }

        if pref.stopMigration {
            updateUiDelegate?.updateUi(info: ["function": "stopButton"])
//            stopButton(self)
            completion("")
            return
        }
        
        var PostXML       = Xml
        var knownEndpoint = true

        var iconName       = ""
//        var iconId_string  = ""
        var iconId         = "0"
        var iconUri        = ""
        
        var theEndpoint    = endpoint
        
        switch endpoint {
        // adjust the where the data is sent
        case "accounts/userid":
            theEndpoint = "jamfusers"
        case "accounts/groupid":
            theEndpoint = "jamfgroups"
        default:
            theEndpoint = endpoint
        }
        
        // strip out <id> tag from XML
        for xmlTag in ["id"] {
            PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
        }
        
        // check scope options for mobiledeviceconfigurationprofiles, osxconfigurationprofiles, restrictedsoftware... - start
        switch endpoint {
        case "osxconfigurationprofiles":
            if !Scope.ocpCopy {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "policies":
            if !Scope.policiesCopy {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "scope", keepTags: false)
            }
            if Scope.policiesDisable {
                PostXML = disable(theXML: PostXML)
            }
        case "macapplications":
            if !Scope.maCopy {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "restrictedsoftware":
            if !Scope.rsCopy {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "mobiledeviceconfigurationprofiles":
            if !Scope.mcpCopy {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "mobiledeviceapplications":
            if !Scope.iaCopy {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "usergroups", "smartusergroups", "staticusergroups":
            if !Scope.usersCopy {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "users", keepTags: false)
            }

        default:
            break
        }
        // check scope options for mobiledeviceconfigurationprofiles, osxconfigurationprofiles, and restrictedsoftware - end
        
        switch endpoint {
        case "buildings", "departments", "diskencryptionconfigurations", "sites", "categories", "dockitems", "softwareupdateservers", "scripts", "printers", "osxconfigurationprofiles", "patchpolicies", "mobiledeviceconfigurationprofiles", "advancedmobiledevicesearches", "mobiledeviceextensionattributes", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups", "mobiledevices", "usergroups", "smartusergroups", "staticusergroups", "userextensionattributes", "advancedusersearches", "restrictedsoftware":
            if LogLevel.debug { WriteToLog.shared.message("[cleanupXml] processing \(endpoint) - verbose") }
            //print("\nXML: \(PostXML)")
            
            // clean up PostXML, remove unwanted/conflicting data
            switch endpoint {
            case "advancedusersearches":
                for xmlTag in ["users"] {
                    PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
                
            case "advancedmobiledevicesearches", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
                //                                 !Scope.sigCopy
                if (PostXML.range(of:"<is_smart>true</is_smart>") != nil || !Scope.sigCopy) {
                    PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "mobile_devices", keepTags: false)
                }
                
//                if itemToSite && JamfProServer.destSite != "" && endpoint != "advancedmobiledevicesearches" {
                if JamfProServer.toSite && JamfProServer.destSite != "" && endpoint != "advancedmobiledevicesearches" {
                    PostXML = setSite(xmlString: PostXML, site: JamfProServer.destSite, endpoint: endpoint)
                }
                
            case "mobiledevices":
                for xmlTag in ["initial_entry_date_epoch", "initial_entry_date_utc", "last_enrollment_epoch", "last_enrollment_utc", "certificates", "configuration_profiles", "provisioning_profiles", "mobile_device_groups", "extension_attributes"] {
                    PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
                
                if JamfProServer.toSite && JamfProServer.destSite != "" {
                    PostXML = setSite(xmlString: PostXML, site: JamfProServer.destSite, endpoint: endpoint)
                }
                
            case "osxconfigurationprofiles", "mobiledeviceconfigurationprofiles":
                // migrating to another site
                if JamfProServer.toSite && JamfProServer.destSite != "" {
                    PostXML = setSite(xmlString: PostXML, site: JamfProServer.destSite, endpoint: endpoint)
                }
                
                if endpoint == "osxconfigurationprofiles" {
                    // check for filevault payload
                    let payload = tagValue2(xmlString: "\(PostXML)", startTag: "<payloads>", endTag: "</payloads>")
                    
                    if payload.range(of: "com.apple.security.FDERecoveryKeyEscrow", options: .caseInsensitive) != nil {
                        let profileName = getName(endpoint: "osxconfigurationprofiles", objectXML: PostXML)
                        knownEndpoint = false

//                        let localTmp = (Counter.shared.crud[endpoint]?["fail"])!
                        Counter.shared.crud[endpoint]?["fail"]! += 1 /*localTmp + 1*/
                        if var summaryArray = Counter.shared.summary[endpoint]?["fail"] {
                            if summaryArray.contains(profileName) == false {
                                summaryArray.append(profileName)
                                Counter.shared.summary[endpoint]?["fail"] = summaryArray
                            }
                        }
                        WriteToLog.shared.message("[cleanUpXml] FileVault payloads are not migrated and must be recreated manually, skipping \(profileName)")
                        Counter.shared.post += 1
                        updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": "osxconfigurationprofiles", "total": endpointCount])
//                        putStatusUpdate(endpoint: "osxconfigurationprofiles", total: endpointCount)
                        if ToMigrate.objects.last == endpoint && endpointCount == endpointCurrent {
                            updateUiDelegate?.updateUi(info: ["function": "rmDELETE"])
        //                    self.resetAllCheckboxes()
//                            print("[\(#function)] \(#line) - finished cleanup")
                            updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                        }
                    }
                }
                if knownEndpoint {
                    // correct issue when an & is in the name of a macOS configuration profiles - real issue is in the encoded payload
                    PostXML = PostXML.replacingOccurrences(of: "&amp;amp;", with: "%26;")
                    //print("\nXML: \(PostXML)")
                    // fix limitations/exclusions LDAP issue
                    for xmlTag in ["limit_to_users"] {
                        PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
                    }
                }
                
            case "usergroups", "smartusergroups", "staticusergroups":
                for xmlTag in ["full_name", "phone_number", "email_address"] {
                    PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
                
            case "scripts":
                for xmlTag in ["script_contents_encoded"] {
                    PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
                // fix to remove parameter labels that have been deleted from existing scripts
//                    let theScript = tagValue(xmlString: PostXML, xmlTag: "script_contents")
//                    print("[cleanup] theScript: \(theScript)")
//                    if theScript != "" {
//                        PostXML = rmXmlData(theXML: PostXML, theTag: "script_contents", keepTags: true)
//                        PostXML = PostXML.replacingOccurrences(of: "<script_contents/>", with: "<script_contents>\(theScript.xmlEncode)</script_contents>")
//                    }
                PostXML = self.parameterFix(theXML: PostXML)
                
            default: break
            }
            
        case "classes":
            // check for Apple School Manager class
            let source = tagValue2(xmlString: "\(PostXML)", startTag: "<source>", endTag: "</source>")
            if source == "Apple School Manager" {
                let className = getName(endpoint: "classes", objectXML: PostXML)
                knownEndpoint = false
                // Apple School Manager class - handle those here
                // update global counters

                let localTmp = (Counter.shared.crud[endpoint]?["fail"])!
                Counter.shared.crud[endpoint]?["fail"] = localTmp + 1
                if var summaryArray = Counter.shared.summary[endpoint]?["fail"] {
                    if summaryArray.contains(className) == false {
                        summaryArray.append(className)
                        Counter.shared.summary[endpoint]?["fail"] = summaryArray
                    }
                }
                WriteToLog.shared.message("[cleanUpXml] Apple School Manager classes are not migrated, skipping \(className)")
                Counter.shared.post += 1
                updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": "classes", "total": endpointCount])
//                putStatusUpdate(endpoint: "classes", total: endpointCount)
                if ToMigrate.objects.last == endpoint && endpointCount == endpointCurrent {
                    //self.go_button.isEnabled = true
                    updateUiDelegate?.updateUi(info: ["function": "rmDELETE"])
//                    self.resetAllCheckboxes()
//                    print("[\(#function)] \(#line) - finished cleanup")
                    updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                }
            } else {
                for xmlTag in ["student_ids", "teacher_ids", "student_group_ids", "teacher_group_ids", "mobile_device_group_ids"] {
                    PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
               for xmlTag in ["student_ids/", "teacher_ids/", "student_group_ids/", "teacher_group_ids/", "mobile_device_group_ids/"] {
                   PostXML = PostXML.replacingOccurrences(of: "<\(xmlTag)>", with: "")
               }
            }

        case "computerextensionattributes":
            if tagValue(xmlString: PostXML, xmlTag: "description") == "Extension Attribute provided by JAMF Nation patch service" {
                knownEndpoint = false
                // Currently patch EAs are not migrated - handle those here
                if Counter.shared.crud[endpoint]?["fail"] != endpointCount-1 {
                    updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpoint, "theColor": "yellow"])
//                    self.labelColor(endpoint: endpoint, theColor: self.yellowText)
                } else {
                    // every EA failed, and a patch EA was the last on the list
                    updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpoint, "theColor": "red"])
//                    self.labelColor(endpoint: endpoint, theColor: self.redText)
                }
                // update global counters
                let patchEaName = getName(endpoint: endpoint, objectXML: PostXML)

                let localTmp = (Counter.shared.crud[endpoint]?["fail"])!
                Counter.shared.crud[endpoint]?["fail"] = localTmp + 1
                if var summaryArray = Counter.shared.summary[endpoint]?["fail"] {
                    if summaryArray.contains(patchEaName) == false {
                        summaryArray.append(patchEaName)
                        Counter.shared.summary[endpoint]?["fail"] = summaryArray
                    }
                }
                WriteToLog.shared.message("[cleanUpXml] Patch EAs are not migrated, skipping \(patchEaName)")
                Counter.shared.post += 1
                if ToMigrate.objects.last == endpoint && endpointCount == endpointCurrent {
                    //self.go_button.isEnabled = true
                    updateUiDelegate?.updateUi(info: ["function": "rmDELETE"])
//                    self.resetAllCheckboxes()
//                    print("[\(#function)] \(#line) - finished cleanup")
                    updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                }
            }
            
        case "directorybindings", "ldapservers","distributionpoints":
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] processing \(endpoint) - verbose") }
            var credentialsArray = [String]()
            var newPasswordXml   = ""

            switch endpoint {
            case "directorybindings", "ldapservers":
                let regexPwd = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.23\">(.*?)</password_sha256>", options:.caseInsensitive)
                if userDefaults.integer(forKey: "prefBindPwd") == 1 && endpoint == "directorybindings" {
                    //setPassword = true
                    accountDict = Credentials.shared.retrieve(service: "migrator-bind", account: "")
                    if accountDict.count != 1 {
                        // set password for bind account since one was not found in the keychain
                        newPasswordXml =  "<password>changeM3!</password>"
                    } else {
                        newPasswordXml = "<password>\(accountDict.password)</password>"
                    }
                }
                if userDefaults.integer(forKey: "prefLdapPwd") == 1 && endpoint == "ldapservers" {
                    accountDict = Credentials.shared.retrieve(service: "migrator-ldap", account: "")
                    if accountDict.count != 1 {
                        // set password for LDAP account since one was not found in the keychain
                        newPasswordXml =  "<password>changeM3!</password>"
                    } else {
                        newPasswordXml = "<password>\(accountDict.password)</password>"
                    }
                }
                PostXML = regexPwd.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "\(newPasswordXml)")
            case "distributionpoints":
                var newPasswordXml2   = ""
                let regexRwPwd = try! NSRegularExpression(pattern: "<read_write_password_sha256 since=\"9.23\">(.*?)</read_write_password_sha256>", options:.caseInsensitive)
                let regexRoPwd = try! NSRegularExpression(pattern: "<read_only_password_sha256 since=\"9.23\">(.*?)</read_only_password_sha256>", options:.caseInsensitive)
                if userDefaults.integer(forKey: "prefFileSharePwd") == 1 && endpoint == "distributionpoints" {
                    accountDict = Credentials.shared.retrieve(service: "migrator-fsrw", account: "")
                    if accountDict.count != 1 {
                        // set password for fileshare RW account since one was not found in the keychain
                        newPasswordXml =  "<read_write_password>changeM3!</read_write_password>"
                    } else {
                        newPasswordXml = "<read_write_password>\(accountDict.password)</read_write_password>"
                    }
                    accountDict  = Credentials.shared.retrieve(service: "migrator-fsro", account: "")
                    if accountDict.count != 1 {
                        // set password for fileshare RO account since one was not found in the keychain
                        newPasswordXml2 =  "<read_only_password>changeM3!</read_only_password>"
                    } else {
                        newPasswordXml2 = "<read_only_password>\(accountDict.password)</read_only_password>"
                    }
                }
                PostXML = regexRwPwd.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "\(newPasswordXml)")
                PostXML = regexRoPwd.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "\(newPasswordXml2)")
            default:
                break
            }

        case "advancedcomputersearches":
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] processing advancedcomputersearches - verbose") }
            // clean up some data from XML
            for xmlTag in ["computers"] {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
            // migrating to another site
            if JamfProServer.toSite && !JamfProServer.destSite.isEmpty {
                PostXML = setSite(xmlString: PostXML, site: JamfProServer.destSite, endpoint: endpoint)
            }
            
        case "computers":
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] processing computers - verbose") }
            // clean up some data from XML
            for xmlTag in ["package", "mapped_printers", "plugins", "report_date", "report_date_epoch", "report_date_utc", "running_services", "licensed_software", "computer_group_memberships"] {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
            // remove Conditional Access ID from record, if selected
            if userDefaults.integer(forKey: "removeCA_ID") == 1 {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "device_aad_infos", keepTags: false)
            }
            
            if JamfProServer.toSite && JamfProServer.destSite != "" {
                PostXML = setSite(xmlString: PostXML, site: JamfProServer.destSite, endpoint: endpoint)
            }
            
            // remote management
            let regexRemote = try! NSRegularExpression(pattern: "<remote_management>(.|\n|\r)*?</remote_management>", options:.caseInsensitive)
            if userDefaults.integer(forKey: "migrateAsManaged") == 1 {
                var accountDict = Credentials.shared.retrieve(service: "migrator-mgmtAcct", account: "")
                if accountDict.count != 1 {
                    // set default management account credentials
                    accountDict["jamfpro_manage"] = "changeM3!"
                }
                PostXML = regexRemote.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: """
            <remote_management>
                <managed>true</managed>
                <management_username>\(accountDict.username)</management_username>
                <management_password>\(accountDict.password)</management_password>
            </remote_management>
""")
            } else {
                PostXML = regexRemote.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: """
            <remote_management>
                <managed>false</managed>
            </remote_management>
""")
            }

            // change serial number 'Not Available' to blank so machines will migrate
            PostXML = PostXML.replacingOccurrences(of: "<serial_number>Not Available</serial_number>", with: "<serial_number></serial_number>")

            PostXML = PostXML.replacingOccurrences(of: "<xprotect_version/>", with: "")
            PostXML = PostXML.replacingOccurrences(of: "<size>0</size>", with: "")
            PostXML = PostXML.replacingOccurrences(of: "<size>-1</size>", with: "")
            let regexAvailable_mb = try! NSRegularExpression(pattern: "<available_mb>-(.*?)</available_mb>", options:.caseInsensitive)
            PostXML = regexAvailable_mb.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<available_mb>1</available_mb>")
            //print("\nXML: \(PostXML)")
            
        case "networksegments":
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] processing network segments - verbose") }
            // remove items not transfered; netboot server, SUS from XML
            let regexDistro1 = try! NSRegularExpression(pattern: "<distribution_server>(.*?)</distribution_server>", options:.caseInsensitive)
//            let regexDistro2 = try! NSRegularExpression(pattern: "<distribution_point>(.*?)</distribution_point>", options:.caseInsensitive)
            let regexDistroUrl = try! NSRegularExpression(pattern: "<url>(.*?)</url>", options:.caseInsensitive)
//            let regexNetBoot = try! NSRegularExpression(pattern: "<netboot_server>(.*?)</netboot_server>", options:.caseInsensitive)
            let regexSUS = try! NSRegularExpression(pattern: "<swu_server>(.*?)</swu_server>", options:.caseInsensitive)
            PostXML = regexDistro1.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_server/>")
            // clear JCDS url from network segments xml - start
            if tagValue2(xmlString: PostXML, startTag: "<distribution_point>", endTag: "</distribution_point>") == "Cloud Distribution Point" {
                PostXML = regexDistroUrl.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<url/>")
            }
            
            // if not migrating software update server remove then from network segments xml - start
            if ToMigrate.objects.firstIndex(of: "softwareupdateservers") == 0 {
                PostXML = regexSUS.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<swu_server/>")
//                }
            // if not migrating software update server remove then from network segments xml - end
            }
            
            //print("\nXML: \(PostXML)")
            
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] processing \(endpoint) - verbose") }
            // remove computers that are a member of a smart group
            if (PostXML.range(of:"<is_smart>true</is_smart>") != nil || !Scope.scgCopy) {
                // groups containing thousands of computers could not be cleared by only using the computers tag
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "computer", keepTags: false)
                PostXML = rmBlankLines(theXML: PostXML)
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: "computers", keepTags: false)
            }
            //            print("\n\(endpoint) XML: \(PostXML)")
            // fix criteria name differences between 11.17 and 11.18+
            if isVersion(JamfProServer.version["dest"] ?? "11.17", greaterThan: "11.18.0") {
                PostXML = PostXML.replacingOccurrences(of: "<name>Packages Installed By Installer.app/SWU</name>", with: "<name>Packages Installed by Installer.app/SWU</name>")
                PostXML = PostXML.replacingOccurrences(of: "<name>Packages Installed By Casper</name>", with: "<name>Packages Installed by Jamf Pro</name>")
            } else {
                PostXML = PostXML.replacingOccurrences(of: "<name>Packages Installed by Installer.app/SWU</name>", with: "<name>Packages Installed By Installer.app/SWU</name>")
                PostXML = PostXML.replacingOccurrences(of: "<name>Packages Installed by Jamf Pro<</name>", with: "<name>Packages Installed By Casper/name>")
            }
            
            // migrating to another site
            if JamfProServer.toSite && JamfProServer.destSite != "" {
                PostXML = setSite(xmlString: PostXML, site: JamfProServer.destSite, endpoint: endpoint)
            }
            
        case "packages":
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] processing packages - verbose") }
            // remove 'No category assigned' from XML
            let regexComp = try! NSRegularExpression(pattern: "<category>No category assigned</category>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<category/>")// clean up some data from XML
            for xmlTag in ["hash_type", "hash_value"] {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
//            print("\nXML: \(PostXML)\n")
            
        case "policies", "macapplications", "mobiledeviceapplications":
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] processing \(endpoint) - verbose") }
            // check for a self service icon and grab name and id if present - start
            // also used for exporting items - iOS
            if PostXML.range(of: "</self_service_icon>") != nil {
                let selfServiceIconXml = tagValue(xmlString: PostXML, xmlTag: "self_service_icon")
                iconName = tagValue(xmlString: selfServiceIconXml, xmlTag: "filename")
                iconUri = tagValue(xmlString: selfServiceIconXml, xmlTag: "uri").replacingOccurrences(of: "//iconservlet", with: "/iconservlet")

                iconId = getIconId(iconUri: iconUri, endpoint: endpoint)
            }
            // check for a self service icon and grab name and id if present - end
            
            if (endpoint == "macapplications") || (endpoint == "mobiledeviceapplications") {  // "vpp_admin_account_id", "total_vpp_licenses", "remaining_vpp_licenses"
                if let index = iconUri.firstIndex(of: "&") {
                    iconUri = String(iconUri.prefix(upTo: index))
                    //                    print("[cleanupXml] adjusted - self service icon name: \(iconName) \t uri: \(iconUri)")
                }
                let regexVPP = try! NSRegularExpression(pattern: "<vpp>(.*?)</vpp>", options:.caseInsensitive)
                PostXML = regexVPP.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<vpp><assign_vpp_device_based_licenses>false</assign_vpp_device_based_licenses><vpp_admin_account_id>-1</vpp_admin_account_id></vpp>")
            }
            
            // fix names that start with spaces - convert space to hex: &#xA0;
            let regexPolicyName = try! NSRegularExpression(pattern: "<name> ", options:.caseInsensitive)
            PostXML = regexPolicyName.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<name>&#xA0;")
            
            for xmlTag in ["limit_to_users","open_firmware_efi_password","self_service_icon"] {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
            
            // update references to the Jamf server - skip if migrating files
            if JamfProServer.source.prefix(4) == "http" {
                let regexServer = try! NSRegularExpression(pattern: JamfProServer.source.fqdnFromUrl, options:.caseInsensitive)
                PostXML = regexServer.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: JamfProServer.destination.fqdnFromUrl)
            }
            
            // set the password used in the accounts payload to jamfchangeme - start
            let regexAccounts = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.23\">(.*?)</password_sha256>", options:.caseInsensitive)
            PostXML = regexAccounts.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<password>jamfchangeme</password>")
            // set the password used in the accounts payload to jamfchangeme - end
            
            let regexComp = try! NSRegularExpression(pattern: "<management_password_sha256 since=\"9.23\">(.*?)</management_password_sha256>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
            //print("\nXML: \(PostXML)")
            
            // resets distribution point (to default) used for policies that deploy packages
//            if endpoint == "policies" {
//                let regexDistro = try! NSRegularExpression(pattern: "<distribution_point>(.*?)</distribution_point>", options:.caseInsensitive)
//                PostXML = regexDistro.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_point>default</distribution_point>")
//            }
            
            // migrating to another site
            if JamfProServer.toSite && JamfProServer.destSite != ""/* && endpoint == "policies"*/ {
                PostXML = setSite(xmlString: PostXML, site: JamfProServer.destSite, endpoint: endpoint)
            }
            
        case "users":
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] processing users - verbose") }
            
            let regexComp = try! NSRegularExpression(pattern: "<self_service_icon>(.*?)</self_service_icon>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<self_service_icon/>")
            // remove photo reference from XML
            for xmlTag in ["enable_custom_photo_url", "custom_photo_url", "links", "ldap_server"] {
                PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
            if JamfProServer.toSite && JamfProServer.destSite != "" {
                PostXML = setSite(xmlString: PostXML, site: JamfProServer.destSite, endpoint: endpoint)
            }
            
        case "jamfusers", "jamfgroups", "accounts/userid", "accounts/groupid":
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] processing jamf users/groups (\(endpoint)) - verbose") }
            // remove password from XML, since it doesn't work on the new server
            let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.32\">(.*?)</password_sha256>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
            //print("\nXML: \(PostXML)")
            // check for LDAP account/group, make adjustment for v10.17+ which needs id rather than name - start
            if tagValue(xmlString: PostXML, xmlTag: "ldap_server") != "" {
                let ldapServerInfo = tagValue(xmlString: PostXML, xmlTag: "ldap_server")
                let ldapServerName = tagValue(xmlString: ldapServerInfo, xmlTag: "name")
                let regexLDAP      = try! NSRegularExpression(pattern: "<ldap_server>(.|\n|\r)*?</ldap_server>", options:.caseInsensitive)
                if !Setting.hardSetLdapId {
                    Setting.ldapId = currentLDAPServers[ldapServerName] ?? -1
                }
                PostXML = regexLDAP.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<ldap_server><id>\(Setting.ldapId)</id></ldap_server>")
            } else if Setting.hardSetLdapId && Setting.ldapId > 0 {
                let ldapObjectUsername = tagValue(xmlString: PostXML, xmlTag: "name").lowercased()
                // make sure we don't change the account we're authenticated to the destination server with
                if ldapObjectUsername != JamfProServer.destUser.lowercased() {
                    let regexNoLdap    = try! NSRegularExpression(pattern: "</full_name>", options:.caseInsensitive)
                    PostXML = regexNoLdap.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "</full_name><ldap_server><id>\(Setting.ldapId)</id></ldap_server>")
                }
            }
//            print("PostXML: \(PostXML)")
            // check for LDAP account/group, make adjustment for v10.17+ which needs id rather than name - end
            if action == "create" {
                // newly created local accounts are disabled
                if PostXML.range(of: "<directory_user>false</directory_user>") != nil {
                    let regexComp1 = try! NSRegularExpression(pattern: "<enabled>Enabled</enabled>", options:.caseInsensitive)
                    PostXML = regexComp1.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<enabled>Disabled</enabled>")
                }
            } else {
                // don't change enabled status of existing accounts on destination server.
                for xmlTag in ["enabled"] {
                    PostXML = RemoveData.shared.Xml(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
            }
            
        default:
            if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] Unknown endpoint: \(endpoint)") }
            knownEndpoint = false
        }   // switch - end
        
        if knownEndpoint {
//            print("\n[cleanupXml] knownEndpoint-PostXML: \(PostXML)")
            var destEndpoint = "skip"
            if (action == "update") && (theEndpoint == "osxconfigurationprofiles") {
                destEndpoint = theEndpoint
            }
            
            XmlDelegate.shared.apiAction(method: "GET", theServer: JamfProServer.destination, base64Creds: JamfProServer.base64Creds["dest"] ?? "", theEndpoint: "\(destEndpoint)/id/\(destEpId)") {
                (xmlResult: (Int,String)) in
                let (_, fullXML) = xmlResult
                
                if fullXML != "" {
                    var destUUID = tagValue2(xmlString: fullXML, startTag: "<general>", endTag: "</general>")
                    destUUID     = tagValue2(xmlString: destUUID, startTag: "<uuid>", endTag: "</uuid>")
//                    print ("  destUUID: \(destUUID)")
                    var sourceUUID = tagValue2(xmlString: PostXML, startTag: "<general>", endTag: "</general>")
                    sourceUUID     = tagValue2(xmlString: sourceUUID, startTag: "<uuid>", endTag: "</uuid>")
//                    print ("sourceUUID: \(sourceUUID)")

                    // update XML to be posted with original/existing UUID of the configuration profile
                    PostXML = PostXML.replacingOccurrences(of: sourceUUID, with: destUUID)
                }
                
                CreateEndpoints.shared.queue(endpointType: theEndpoint, endpointName: destEpName, endPointXML: PostXML, endpointCurrent: Int(endpointCurrent), endpointCount: endpointCount, action: action, sourceEpId: Int(endpointID)!, destEpId: "\(destEpId)", ssIconName: iconName, ssIconId: iconId, ssIconUri: iconUri, retry: false) {
                    (result: String) in
                    if LogLevel.debug { WriteToLog.shared.message("[cleanUpXml] call to createEndpointsQueue result: \(result)") }
                    if endpointCurrent == endpointCount {
//                        print("completed \(endpointCurrent) of \(endpointCount) - created last endpoint")
                        completion("last")
                    } else {
//                        print("completed \(endpointCurrent) of \(endpointCount) - created next endpoint")
                        completion("")
                    }
                }
            }
        } else {    // if knownEndpoint - end
            if endpointCurrent == endpointCount {
                if LogLevel.debug { WriteToLog.shared.message("[cleanupXml] Last item in \(theEndpoint) was unkown.") }
                nodesMigrated+=1
                completion("last")
                // ;print("added node: \(localEndPointType) - createEndpoints")
                //                    print("nodes complete: \(nodesMigrated)")
            } else {
                completion("")
            }
        }
    }
    
    fileprivate func disable(theXML: String) -> String {
        logFunctionCall()
        let regexDisable    = try? NSRegularExpression(pattern: "<enabled>true</enabled>", options:.caseInsensitive)
        let newXML          = (regexDisable?.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "<enabled>false</enabled>"))!
  
        return newXML
    }
    
    fileprivate func parameterFix(theXML: String) -> String {
        logFunctionCall()
        
        let parameterRegex  = try! NSRegularExpression(pattern: "</parameters>", options:.caseInsensitive)
        var updatedScript   = theXML
        var scriptParameter = ""
        
        // add parameter keys for those with no value
        for i in (4...11) {
            scriptParameter = tagValue2(xmlString: updatedScript, startTag: "parameter\(i)", endTag: "parameter\(i)")
            if scriptParameter == "" {
                updatedScript = parameterRegex.stringByReplacingMatches(in: updatedScript, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "<parameter\(i)></parameter\(i)></parameters>")
            }
        }

        return updatedScript
    }
    
    fileprivate func setSite(xmlString: String, site: String, endpoint: String) -> String {
        logFunctionCall()
        var rawValue = ""
//        var startTag = ""
        let siteEncoded = XmlDelegate.shared.encodeSpecialChars(textString: site)
        print("[setSite] endpoint: \(endpoint)")
        // get copy / move preference - start
        switch endpoint {
        case "macapplications", "mobiledeviceapplications":
            sitePref = userDefaults.string(forKey: "siteAppsAction") ?? "Copy"
            
        case "advancedcomputersearches", "advancedmobiledevicesearches":
            sitePref = userDefaults.string(forKey: "siteSearchesAction") ?? "Copy"
            
        case "computergroups", "smartcomputergroups", "staticcomputergroups", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            sitePref = userDefaults.string(forKey: "siteGroupsAction") ?? "Copy"
            
        case "policies":
            sitePref = userDefaults.string(forKey: "sitePoliciesAction") ?? "Copy"
            
        case "osxconfigurationprofiles", "mobiledeviceconfigurationprofiles":
            sitePref = userDefaults.string(forKey: "siteProfilesAction") ?? "Copy"
            
        case "restrictedsoftware":
            sitePref = userDefaults.string(forKey: "restrictedsoftware") ?? "Copy"

        case "computers","mobiledevices":
            sitePref = "Move"
            
        default:
            sitePref = "Copy"
        }
        
        if LogLevel.debug { WriteToLog.shared.message("[siteSet] site operation for \(endpoint): \(sitePref)") }
        // get copy / move preference - end
        
        /*
        switch endpoint {
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            rawValue = tagValue2(xmlString: xmlString, startTag: "<computer_group>", endTag: "</computer_group>")
//            startTag = "computer_group"
            
        case "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            rawValue = tagValue2(xmlString: xmlString, startTag: "<mobile_device_group>", endTag: "</mobile_device_group>")
//            startTag = "mobile_device_group"
            
        default:
            rawValue = tagValue2(xmlString: xmlString, startTag: "<general>", endTag: "</general>")
//            startTag = "general"
        }
        */
        
        var itemName = "unknown object name"
//        let itemName = tagValue2(xmlString: rawValue, startTag: "<name>", endTag: "</name>")
        if let firstNameValue = parser.findFirstTagValue(tagName: "name", in: xmlString) {
            itemName = firstNameValue
        }
        
        // update site
        //WriteToLog.shared.message("[siteSet] endpoint \(endpoint) to site \(siteEncoded)")
        if endpoint != "users" {
            let siteInfo = tagValue2(xmlString: xmlString, startTag: "<site>", endTag: "</site>")
            let currentSiteName = tagValue2(xmlString: siteInfo, startTag: "<name>", endTag: "</name>")
            
            rawValue = clearTagValue(key: "site", keyValue: xmlString)
            rawValue = rawValue.replacingOccurrences(of: "<site></site>", with: "<site><name>\(siteEncoded)</name></site>")
            rawValue = rawValue.replacingOccurrences(of: "<site/>", with: "<site><name>\(siteEncoded)</name></site>")
            
//            rawValue = xmlString.replacingOccurrences(of: "<site><name>\(currentSiteName)</name></site>", with: "<site><name>\(siteEncoded)</name></site>")
            if LogLevel.debug { WriteToLog.shared.message("[siteSet] changing site from \(currentSiteName) to \(siteEncoded)") }
        } else {
            // remove current sites info
            rawValue = RemoveData.shared.Xml(theXML: xmlString, theTag: "sites", keepTags: true)

//            let siteInfo = tagValue2(xmlString: xmlString, startTag: "<sites>", endTag: "</sites>")
            if siteEncoded.lowercased() != "none" {
                rawValue = xmlString.replacingOccurrences(of: "<sites></sites>", with: "<sites><site><name>\(siteEncoded)</name></site></sites>")
                rawValue = xmlString.replacingOccurrences(of: "<sites/>", with: "<sites><site><name>\(siteEncoded)</name></site></sites>")
            }
            if LogLevel.debug { WriteToLog.shared.message("[siteSet] changing site to \(siteEncoded)") }
        }
        
        // do not redeploy profile to existing scope
        if endpoint == "osxconfigurationprofiles" || endpoint == "mobiledeviceconfigurationprofiles" {
            let regexComp = try! NSRegularExpression(pattern: "<redeploy_on_update>(.*?)</redeploy_on_update>", options:.caseInsensitive)
            rawValue = regexComp.stringByReplacingMatches(in: rawValue, options: [], range: NSRange(0..<rawValue.utf16.count), withTemplate: "<redeploy_on_update>Newly Assigned</redeploy_on_update>")
        }
        
        if sitePref == "Copy" && endpoint != "users" && endpoint != "computers" {
            // update item Name - ...<name>currentName - site</name>
            
//            rawValue = rawValue.replacingOccurrences(of: "<\(startTag)><name>\(itemName)</name>", with: "<\(startTag)><name>\(itemName) - \(siteEncoded)</name>")
            
//            rawValue = rawValue.replacingOccurrences(of: "><", with: ">\n<")
            
            rawValue = updateFirstName(in: rawValue, newName: "\(itemName) - \(siteEncoded)")
            
            // generate a new uuid for configuration profiles - start -- needed?  New profiles automatically get new UUID?
            if endpoint == "osxconfigurationprofiles" || endpoint == "mobiledeviceconfigurationprofiles" {
                let profileGeneral = tagValue2(xmlString: xmlString, startTag: "<general>", endTag: "</general>")
                let payloadUuid    = tagValue2(xmlString: profileGeneral, startTag: "<uuid>", endTag: "</uuid>")
                let newUuid        = UUID().uuidString
                
                rawValue = rawValue.replacingOccurrences(of: payloadUuid, with: newUuid)
//                print("[setSite] rawValue2: \(rawValue)")
            }
            // generate a new uuid for configuration profiles - end
            
            // update scope - start
            rawValue = rawValue.replacingOccurrences(of: "><", with: ">\n<")
            let rawValueArray = rawValue.split(separator: "")
            rawValue = ""
            var currentLine = 0
            let numberOfLines = rawValueArray.count
            while true {
                rawValue.append("\(rawValueArray[currentLine])")
                if currentLine+1 < numberOfLines {
                    currentLine+=1
                } else {
                    break
                }
                if rawValueArray[currentLine].contains("<scope>") {
                    while !rawValueArray[currentLine].contains("</scope>") {
                        if rawValueArray[currentLine].contains("<computer_group>") || rawValueArray[currentLine].contains("<mobile_device_group>") {
                            rawValue.append("\(rawValueArray[currentLine])")
                            if currentLine+1 < numberOfLines {
                                currentLine+=1
                            } else {
                                break
                            }
                            let siteGroupName = rawValueArray[currentLine].replacingOccurrences(of: "</name>", with: " - \(siteEncoded)</name>")
                            
                            //                print("siteGroupName: \(siteGroupName)")
                            
                            rawValue.append("\(siteGroupName)")
                            if currentLine+1 < numberOfLines {
                                currentLine+=1
                            } else {
                                break
                            }
                        } else {  // if rawValueArray[currentLine].contains("<computer_group>") - end
                            rawValue.append("\(rawValueArray[currentLine])")
                            if currentLine+1 < numberOfLines {
                                currentLine+=1
                            } else {
                                break
                            }
                        }
                    }   // while !rawValueArray[currentLine].contains("</scope>")
                }   // if rawValueArray[currentLine].contains("<scope>")
            }   // while true - end
            // update scope - end
        }   // if sitePref - end
                
        return rawValue
    }
    
    fileprivate func rmBlankLines(theXML: String) -> String {
        logFunctionCall()
        if LogLevel.debug { WriteToLog.shared.message("Removing blank lines.") }
        let f_regexComp = try! NSRegularExpression(pattern: "\n\n", options:.caseInsensitive)
        let newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")
//        let newXML_trimmed = newXML.replacingOccurrences(of: "\n\n", with: "")
        return newXML
    }
    
    private func clearTagValue(key: String, keyValue: String) -> String {
        if LogLevel.debug { WriteToLog.shared.message("Clearing tag value: \(keyValue)") }
        let pattern = "(?<=<\(key)>).*?(?=</\(key)>)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: keyValue.utf16.count)
            let result = regex.stringByReplacingMatches(in: keyValue, options: [], range: range, withTemplate: "")
            return result
        }
        return ""
    }
    
    private func updateFirstName(in xmlString: String, newName: String) -> String {
        // Find first <name>...</name> and replace its content
        let pattern = "(<name>)[^<]*(</name>)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return xmlString
        }
            
//            let safeName = newName
//                .replacingOccurrences(of: "\\", with: "\\\\")
//                .replacingOccurrences(of: "$", with: "\\$")
            
        guard let match = regex.firstMatch(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString)) else {
            return xmlString
        }
        
        return regex.stringByReplacingMatches(
            in: xmlString,
            options: [],
            range: match.range,
            withTemplate: "$1\(newName)$2"
        )
    }
}
