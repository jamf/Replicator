//
//  Queues.swift
//  Replicator
//
//  Created by leslie on 6/28/25.
//  Copyright © 2025 Jamf. All rights reserved.
//

import Foundation

final class DestinationGetQueue {
    static let shared = DestinationGetQueue()
    
    let operationQueue: OperationQueue

    private init() {
        let queue = OperationQueue()
        queue.name = "jamf.replicator.destinationGetQueue"
        queue.maxConcurrentOperationCount = maxConcurrentThreads
        queue.qualityOfService = .userInteractive
        self.operationQueue = queue
    }

    func addOperation(_ block: @escaping () -> Void) {
        operationQueue.addOperation(block)
    }
}
 
final class SourceGetQueue {
    static let shared = SourceGetQueue()
    
    let operationQueue: OperationQueue

    private init() {
        let queue = OperationQueue()
        queue.name = "jamf.replicator.sourceGetQueue"
        queue.maxConcurrentOperationCount = maxConcurrentThreads
        queue.qualityOfService = .userInteractive
        self.operationQueue = queue
    }

    func addOperation(_ block: @escaping () -> Void) {
        operationQueue.addOperation(block)
    }
}

final class SendQueue {
  static let shared = SendQueue()
  
  let operationQueue: OperationQueue
  
  private init() {
      let queue = OperationQueue()
      queue.name = "jamf.replicator.sendQueue"
      queue.maxConcurrentOperationCount = maxConcurrentThreads
      queue.qualityOfService = .userInteractive
      self.operationQueue = queue
  }
  
  func addOperation(_ block: @escaping () -> Void) {
      operationQueue.addOperation(block)
      }
  }

