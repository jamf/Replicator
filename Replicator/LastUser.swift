//
//  LastUser.swift
//  Replicator
//
//  Created by leslie on 3/14/25.
//  Copyright © 2025 Jamf. All rights reserved.
//

import Foundation

// Define a Codable struct for each entry
struct ServerEntry: Codable {
    var server: String
    var lastUser: String?
    var apiClient: Bool?

    // Custom decoding to handle missing values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        server    = try container.decode(String.self, forKey: .server)
        lastUser  = try container.decodeIfPresent(String.self, forKey: .lastUser) ?? ""
        apiClient = try container.decodeIfPresent(Bool.self, forKey: .apiClient) ?? false
    }

    // Default initializer
    init(server: String, lastUser: String? = nil, apiClient: Bool? = nil) {
        self.server    = server
        self.lastUser  = lastUser ?? ""
        self.apiClient = apiClient ?? false
    }
}

// Class to manage the array of dictionaries
class LastUserManager {
    private var servers: [ServerEntry] = []
//    private let filePath: String

    init() {
//        let homeDir = NSHomeDirectory()
//        let fileURL = homeDir + "/Library/Application Support/Replicator/lastUser.json"
//        self.filePath = fileURL
        loadFromFile()
    }
    
    // Load JSON from file
    func loadFromFile() {
        guard FileManager.default.fileExists(atPath: AppInfo.lastUserPath) else {
            print("File does not exist, starting with an empty list.")
            return
        }
        let fileURL = URL(fileURLWithPath: AppInfo.lastUserPath)
        do {
            let data = try Data(contentsOf: fileURL)
            servers = try JSONDecoder().decode([ServerEntry].self, from: data)
        } catch {
            print("Failed to read JSON from file: \(error)")
        }
    }
    
    // Save JSON to file
    func saveToFile() {
        let fileURL = URL(fileURLWithPath: AppInfo.lastUserPath)
        do {
            let data = try JSONEncoder().encode(servers)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save JSON to file: \(error)")
        }
    }
    
    // Convert to JSON string
    func jsonString() -> String {
        do {
            let data = try JSONEncoder().encode(servers)
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            print("Failed to encode JSON: \(error)")
            return "[]"
        }
    }
    
    // Add a new entry
    func add(server: String, lastUser: String? = nil, apiClient: Bool? = nil) {
        servers.append(ServerEntry(server: server, lastUser: lastUser, apiClient: apiClient))
        saveToFile()
    }
    
    // Remove an entry by server name
    func remove(server: String) {
        servers.removeAll { $0.server == server }
        saveToFile()
    }
    
    // Update an existing entry
    func update(server: String, lastUser: String?, apiClient: Bool?) {
        if let index = servers.firstIndex(where: { $0.server == server }) {
            if let lastUser = lastUser {
                servers[index].lastUser = lastUser
            }
            if let apiClient = apiClient {
                servers[index].apiClient = apiClient
            }
            saveToFile()
        }
    }
    
    // Query by server name
    func query(server: String) -> (lastUser: String, apiClient: Bool)? {
        print("lastUser query \(server)")
        if let entry = servers.first(where: { $0.server == server }) {
            print("lastUser query lastUser: \(entry.lastUser ?? ""), apiClient: \(entry.apiClient ?? false)")
            return (entry.lastUser ?? "", entry.apiClient ?? false)
        }
        return nil
    }
}

/*
// Example Usage
let manager = ServerManager()
manager.add(server: "server1.example.com", lastUser: "admin", apiClient: true)
manager.add(server: "server2.example.com", lastUser: "user", apiClient: false)

if let result = manager.query(server: "server1.example.com") {
    print("Last User: \(result.lastUser), API Client: \(result.apiClient)")
    update(server: server, lastUser: <lastUser>, apiClient: <useApiClient>)
} else {
    print("Server not found.")
    add(server: server, lastUser: <lastUser>, apiClient: <useApiClient>)
}
*/
