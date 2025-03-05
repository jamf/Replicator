//
//  CheckForUpdate.swift
//  Replicator
//
//  Created by Leslie Helou on 6/9/18.
//  Copyright 2024 Jamf. All rights reserved.
//

import Foundation

class VersionCheck: NSObject, URLSessionDelegate {
    
    func versionCheck(completion: @escaping (_ result: Bool, _ latest: String) -> Void) {
        
        URLCache.shared.removeAllCachedResponses()

//        let (currMajor, currMinor, currPatch, runningBeta, currBeta) = versionDetails(theVersion: AppInfo.version)
        
        var updateAvailable = false
//        var versionTest     = true
        
        let versionUrl = URL(string: "https://api.github.com/repos/jamf/Replicator/releases/latest")

        let configuration = URLSessionConfiguration.ephemeral
        var request = URLRequest(url: versionUrl!)
        request.httpMethod = "GET"
        
        configuration.httpAdditionalHeaders = ["Accept" : "application/vnd.github.jean-grey-preview+json"]
        
        var headers = [String: String]()
        for (header, value) in configuration.httpAdditionalHeaders ?? [:] {
            headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
        }
        print("[apiCall] \(#function.description) method: \(request.httpMethod ?? "")")
        print("[apiCall] \(#function.description) headers: \(headers)")
        print("[apiCall] \(#function.description) endpoint: \(versionUrl?.absoluteString ?? "")")
        print("[apiCall]")
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json as? [String: Any] {
                        let fullVersion = (endpointJSON["tag_name"] as! String).replacingOccurrences(of: "v", with: "")
                        updateAvailable = self.update(current: AppInfo.version, available: fullVersion)
                        completion(updateAvailable, "v\(fullVersion)")
                        return
                    } else {
                        completion(false, "")
                        return
                    }
                } else {
                    WriteToLog.shared.message("[versionCheck] response error: \(httpResponse.statusCode)")
                    completion(false, "")
                    return
                }
                
            } else {
                WriteToLog.shared.message("[versionCheck] unknown response for version check")
                completion(false, "")
                return
            }
        })
        task.resume()
    }
    
    func update(current: String, available: String) -> Bool  {
        let sortedVersions = [current, available].sorted { current, available in
            let options: String.CompareOptions = [.numeric]
            return current.compare(available, options: options) == .orderedDescending
        }
        return (sortedVersions[0] == available)
    }
    
//    func compareVersions(currMajor: Int, currMinor: Int, currPatch: Int, runningBeta: Bool, currBeta: Int, available: String) -> Bool {
//        var runningCurrent = true
//        var betaVer = ""
//        if runningBeta {
//            betaVer = "b\(currBeta)"
//        }
//        if available != "\(currMajor).\(currMinor).\(currPatch)\(betaVer)" {
//            let (availMajor, availMinor, availPatch, availBeta, availBetaVer) = versionDetails(theVersion: available)
//            if availMajor > currMajor {
//                runningCurrent = false
//            } else if availMajor == currMajor {
//                if availMinor > currMinor {
//                    runningCurrent = false
//                } else if availMinor == currMinor {
//                    if availPatch > currPatch {
//                        runningCurrent = false
//                    } else if availPatch == currPatch && ((runningBeta && availBeta) || (runningBeta && !availBeta))  {
//                        if availBetaVer > currBeta {
//                            runningCurrent = false
//                        }
//                    }
//                }
//            }
//        }
//        return runningCurrent
//    }
    
//    func versionDetails(theVersion: String) -> (Int, Int, Int, Bool, Int) {
//        var major   = 0
//        var minor   = 0
//        var patch   = 0
//        var betaVer = 0
//        var isBeta  = false
//        
//        let versionArray = theVersion.split(separator: ".")
//        if versionArray.count > 2 {
//
//            major = Int(versionArray[0])!
//            minor = Int(versionArray[1])!
//            let patchArray = versionArray[2].lowercased().split(separator: "-")
//            patch = Int(patchArray[0]) ?? 0
//            if patchArray.count > 1 {
//                isBeta = true
//                betaVer = Int(patchArray[1].dropFirst()) ?? 0
//            }
//        }
//        return (major, minor, patch, isBeta, betaVer)
//    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
