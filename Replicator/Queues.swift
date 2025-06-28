//
//  Queues.swift
//  Replicator
//
//  Created by leslie on 6/28/25.
//  Copyright © 2025 Jamf. All rights reserved.
//

import Foundation

/*
final class SendQueue {
    static let shared = SendQueue()
    
    let operationQueue: OperationQueue
    private let monitorQueue = DispatchQueue(label: "replicator.sendQueue.queueMonitor", qos: .background)
    private var isMonitoring = false
    private let monitorLock = NSLock()

    /// Called when the queue becomes empty.
    var onQueueEmpty: (() -> Void)?

    private init() {
        let queue = OperationQueue()
        queue.name = "jamf.replicator.sendQueue"
        queue.maxConcurrentOperationCount = maxConcurrentThreads
        queue.qualityOfService = .userInitiated
        self.operationQueue = queue
    }

    func addOperation(_ block: @escaping () -> Void) {
        operationQueue.addOperation(block)
        startMonitoring()
    }

    private func startMonitoring() {
        monitorLock.lock()
        defer { monitorLock.unlock() }

        guard !isMonitoring else { return }
        isMonitoring = true

        monitorQueue.async { [weak self] in
            guard let self = self else { return }

            while true {
                // Sleep briefly to avoid busy-waiting
                Thread.sleep(forTimeInterval: 1.0)

                if self.operationQueue.operationCount == 0 {
                    self.isMonitoring = false
                    DispatchQueue.main.async {
                        self.onQueueEmpty?()
                    }
                    break
                }
            }
        }
    }
}
 */

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

