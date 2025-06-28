//
//  Queues.swift
//  Replicator
//
//  Created by leslie on 6/28/25.
//  Copyright © 2025 Jamf. All rights reserved.
//

import Foundation

final class CreateQueue {
    static let shared = CreateQueue()
    
    let operationQueue: OperationQueue

    private init() {
        let queue = OperationQueue()
        queue.name = "jamf.replicator.creeteQueue"
        queue.maxConcurrentOperationCount = maxConcurrentThreads
        queue.qualityOfService = .userInteractive
        self.operationQueue = queue
    }

    func addOperation(_ block: @escaping () -> Void) {
        operationQueue.addOperation(block)
    }
}

