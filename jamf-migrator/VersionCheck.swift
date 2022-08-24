//
//  CheckForUpdate.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 6/9/18.
//  Copyright © 2018 jamf. All rights reserved.
//

//import Cocoa
import Foundation

class VersionCheck: NSObject, URLSessionDelegate {
    
    func versionCheck(completion: @escaping (_ result: Bool, _ latest: String) -> Void) {
        
        URLCache.shared.removeAllCachedResponses()

        let (currMajor, currMinor, currPatch, runningBeta, currBeta) = versionDetails(theVersion: appInfo.version)
        
        var updateAvailable = false
        var versionTest     = true
        
        let versionUrl = URL(string: "https://api.github.com/repos/jamf/JamfMigrator/releases/latest")

        let configuration = URLSessionConfiguration.ephemeral
        var request = URLRequest(url: versionUrl!)
        request.httpMethod = "GET"
        
        configuration.httpAdditionalHeaders = ["Accept" : "application/vnd.github.jean-grey-preview+json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json as? [String: Any] {
                        
                        let fullVersion = (endpointJSON["tag_name"] as! String).replacingOccurrences(of: "v", with: "")

                            if !runningBeta && fullVersion.firstIndex(of: "b") == nil {
                                versionTest = self.compareVersions(currMajor: currMajor,
                                                                       currMinor: currMinor,
                                                                       currPatch: currPatch,
                                                                       runningBeta: runningBeta,
                                                                       currBeta: currBeta,
                                                                       available: fullVersion)
                            } else if runningBeta && fullVersion.firstIndex(of: "b") != nil {
                                versionTest = self.compareVersions(currMajor: currMajor,
                                                                       currMinor: currMinor,
                                                                       currPatch: currPatch,
                                                                       runningBeta: runningBeta,
                                                                       currBeta: currBeta,
                                                                       available: fullVersion)
                            }
                            if !versionTest {
                                updateAvailable = true
                            }
//                        }
                        completion(updateAvailable, "v\(fullVersion)")
                        return
                    } else {    // if let endpointJSON error
                        completion(false, "")
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    WriteToLog().message(stringOfText: "[versionCheck] response error: \(httpResponse.statusCode)\n")
                    completion(false, "")
                    return
                }
                
            }
        })
        task.resume()
    }
    
    func compareVersions(currMajor: Int, currMinor: Int, currPatch: Int, runningBeta: Bool, currBeta: Int, available: String) -> Bool {
        var runningCurrent = true
        var betaVer = ""
        if runningBeta {
            betaVer = "b\(currBeta)"
        }
        if available != "\(currMajor).\(currMinor).\(currPatch)\(betaVer)" {
            let (availMajor, availMinor, availPatch, availBeta, availBetaVer) = versionDetails(theVersion: available)
            if availMajor > currMajor {
                runningCurrent = false
            } else if availMajor == currMajor {
                if availMinor > currMinor {
                    runningCurrent = false
                } else if availMinor == currMinor {
                    if availPatch > currPatch {
                        runningCurrent = false
                    } else if availPatch == currPatch && ((runningBeta && availBeta) || (runningBeta && !availBeta))  {
                        if availBetaVer > currBeta {
                            runningCurrent = false
                        }
                    }
                }
            }
        }
        return runningCurrent
    }
    
    func versionDetails(theVersion: String) -> (Int, Int, Int, Bool, Int) {
        var major   = 0
        var minor   = 0
        var patch   = 0
        var betaVer = 0
        var isBeta  = false
        
        let versionArray = theVersion.split(separator: ".")
        if versionArray.count > 2 {

            major = Int(versionArray[0])!
            minor = Int(versionArray[1])!
            let patchArray = versionArray[2].lowercased().split(separator: "b")
            patch = Int(patchArray[0])!
            if patchArray.count > 1 {
                isBeta = true
                betaVer = Int(patchArray[1])!
            }
        }
        return (major, minor, patch, isBeta, betaVer)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
