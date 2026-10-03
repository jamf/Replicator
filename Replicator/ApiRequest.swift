//
//  ApiRequest.swift
//  Replicator
//
//  Created by Jordy Thery on 10/3/26.
//  Copyright © 2026 Jamf. All rights reserved.
//

import Foundation

// centralizes URL and request header construction for Classic and Jamf Pro API calls
class ApiRequest: NSObject {

    // whether the server is a platform API gateway (https://us|eu|apac.api.jamfcloud.com) rather than a Jamf Pro instance
    class func isPlatformGateway(_ serverUrl: String) -> Bool {
        return serverUrl.contains(".api.jamfcloud.com")
    }

    // the scheme and host of the server, without any path components
    class func serverRoot(_ serverUrl: String) -> String {
        let urlParts = serverUrl.components(separatedBy: "/")
        return urlParts.count > 2 ? "\(urlParts[0])//\(urlParts[2])" : serverUrl
    }

    // build the full URL for an endpoint, e.g. path: JSSResource/policies/id/5 or api/v1/buildings
    class func endpointUrl(onServer serverUrl: String, path: String) -> String {
        var adjustedServer = serverUrl
        var adjustedPath   = path.hasPrefix("/") ? String(path.dropFirst()) : path
        // route Classic and Jamf Pro API calls through the platform API gateway namespaces
        if isPlatformGateway(serverUrl) {
            adjustedServer = serverRoot(serverUrl)
            if adjustedPath.hasPrefix("JSSResource") {
                adjustedPath = "proclassic" + adjustedPath.dropFirst("JSSResource".count)
            } else if adjustedPath.hasPrefix("api/") {
                adjustedPath = "pro/" + adjustedPath.dropFirst("api/".count)
            }
        }
        while adjustedServer.last == "/" {
            adjustedServer = "\(adjustedServer.dropLast(1))"
        }
        return "\(adjustedServer)/\(adjustedPath)"
    }

    // build the full URL for an endpoint on the source or destination server
    class func endpointUrl(whichServer: String, path: String) -> String {
        let serverUrl = (whichServer == "source") ? JamfProServer.source : JamfProServer.destination
        return endpointUrl(onServer: serverUrl, path: path)
    }

    // authorization header value for the server
    // tokenOnly: always use the bearer token (Jamf Pro API); otherwise use the stored auth type, which can fall back to Basic
    class func authorization(whichServer: String, tokenOnly: Bool = false) -> String {
        return tokenOnly ? "Bearer \(JamfProServer.accessToken[whichServer] ?? "")" : "\(JamfProServer.authType[whichServer] ?? "Bearer") \(JamfProServer.authCreds[whichServer] ?? "")"
    }

    // context headers required by the platform API gateway, empty for direct server connections
    class func scopeHeaders(whichServer: String) -> [String: String] {
        let environmentId = JamfProServer.environmentId[whichServer] ?? ""
        return environmentId.isEmpty ? [:] : ["X-Environment-Id" : environmentId]
    }

    // standard headers for an API call
    class func headers(whichServer: String, contentType: String, accept: String, tokenOnly: Bool = false) -> [String: String] {
        var allHeaders = ["Authorization" : authorization(whichServer: whichServer, tokenOnly: tokenOnly), "Content-Type" : contentType, "Accept" : accept, "User-Agent" : AppInfo.userAgentHeader]
        for (header, value) in scopeHeaders(whichServer: whichServer) {
            allHeaders[header] = value
        }
        return allHeaders
    }
}
