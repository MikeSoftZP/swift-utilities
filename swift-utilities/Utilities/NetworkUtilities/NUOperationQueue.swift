//
//  NUOperationQueue.swift
//  PhotoBackup
//
//  Created by Mike Ponomaryov on 13.07.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import Foundation
import ObjectiveC

typealias NUOperationQueueCompletionBlock = (_ operationQueue: NUOperationQueue) -> Void

class NUOperationQueue {

    private enum Constants {
        static let concurrentQueueLabelPrefix = "NUOperationQueue (Concurrent) "
        static let concurrentTasksCount: Int = 1
        static let enableLogging: Bool = false
    }
    
    var identifier: String
    var waitForNextOperations = false
    
    private(set) var isExecuting = false
    private var _operations: [NUOperation] = []
    private(set) var operations: [NUOperation] {
        get {
            synchronized(_operations) {
                return _operations
            }
        }
        set {
            synchronized(_operations) {
                _operations = newValue
            }
        }
    }
    
    private let concurrentQueue: DispatchQueue
    private let concurrentQueueSemaphore: DispatchSemaphore

    private var completionBlock: NUOperationQueueCompletionBlock?
    
    init(tasksPerTime: Int = Constants.concurrentTasksCount) {
        let uuid = UUID().uuidString
        let concurrentQueueLabel = Constants.concurrentQueueLabelPrefix + uuid
        concurrentQueue = DispatchQueue(label: concurrentQueueLabel, attributes: .concurrent)
        concurrentQueueSemaphore = DispatchSemaphore(value: tasksPerTime)
        identifier = uuid
        debugPrint("Queue (\(identifier)) - init")
    }
    
    deinit {
        debugPrint("Semaphore state: \(concurrentQueueSemaphore.debugDescription) - deinit")
        debugPrint("Queue (\(identifier)) - deinit")
    }
    
    func start(completion: NUOperationQueueCompletionBlock? = nil) {
        if (self.operations.isEmpty && !waitForNextOperations) || self.isExecuting {
            return
        }
            
        self.isExecuting = true
        self.completionBlock = completion
        MemoryHolder.shared.hold(object: self)
            
        self.startAllOperations()
//        self.startNextOperation()
    }
    
    func stop() {
        self.isExecuting = false
        self.completionBlock = nil
        for operation in self.operations {
            cancelOperation(operation)
        }
        
        MemoryHolder.shared.unhold(object: self)
    }
    
    func add(operation: NUOperation) {
        insert(operation: operation)
    }
    
    func add(operations: [NUOperation]) {
        for operation in operations {
            insert(operation: operation)
        }
    }
    
    func insert(operation: NUOperation, at index: Int = .max) {
            let idx = min(max(0, index), self.operations.count)
            let isCompleted = self.isCompleted()
            
            if self.waitForNextOperations {
                self.operations.insert(operation, at: idx)
                self.startAllOperations()
            } else {
                if self.isExecuting {
                    self.operations.insert(operation, at: idx)
                    self.startAllOperations()
                } else {
                    if !isCompleted {
                        self.operations.insert(operation, at: idx)
                        self.startAllOperations()
                    } else {
                        print("Can't add operations after queue's completion")
                    }
                }
            }
    }
    
    func remove(operation: NUOperation) {
        self.cancelOperation(operation)
        self.operations.remove(object: operation)
//        self.operations = self.operations.filter(){ $0 != operation }
    }
}

private extension NUOperationQueue {
    
    func isCompleted() -> Bool {
        let count = operations.count
        let inactiveCount = operations.filter({ $0.isDoneOrCancelled() }).count
        
        return count == 0 ? false : count == inactiveCount
    }
    
    func startAllOperations() {
        for operation in self.operations {
            if operation.status != .idle || operation.queued {
                continue
            }
            operation.queued = true
            operation.queueCompletionBlock = queueCompletionClosure(_:)
            
            self.concurrentQueue.async {
                self.debugPrint("Semaphore state: \(self.concurrentQueueSemaphore.debugDescription) - before wait")
                self.concurrentQueueSemaphore.wait()
                self.debugPrint("Semaphore state: \(self.concurrentQueueSemaphore.debugDescription) - after wait")
                
                operation.status = .executing
            }
        }
    }
    
    func cancelOperation(_ operation: NUOperation) {
        if operation.queueCompletionBlock != nil {
            DispatchQueue.main.syncSafely {
                operation.queueCompletionBlock = nil
                debugPrint("Semaphore state: \(concurrentQueueSemaphore.debugDescription) - cancelling")
                self.concurrentQueueSemaphore.signal()
            }
        }
        if operation.status == .idle || operation.status == .executing {
            DispatchQueue.main.syncSafely {
                operation.cancel()
            }
        }
    }
    
    func queueCompletionClosure(_ operation: NUOperation) -> Void {
        DispatchQueue.main.syncSafely {
            operation.queueCompletionBlock = nil
            
            let isCompleted = self.isCompleted()
            let inactiveCount = self.operations.filter({ $0.isDoneOrCancelled() }).count
            self.debugPrint("completed: \(inactiveCount), total: \(self.operations.count)")
            self.concurrentQueueSemaphore.signal()
            self.debugPrint("Semaphore state: \(self.concurrentQueueSemaphore.debugDescription)")
            
            let unlockedCount = self.operations.filter({ $0.queueCompletionBlock == nil }).count
            
            if isCompleted && unlockedCount == self.operations.count {
                if !self.waitForNextOperations {
                    self.completionBlock?(self)
                    self.stop()
                } else {
                    self.completionBlock?(self)
                }
            }
        }
    }

    func debugPrint(_ message: String) {
        if Constants.enableLogging {
            print(message)
        }
    }
}

private extension NUOperation {
    
    private struct AssociatedKey {
        static var extensionKey = "queued"
    }
    
    var queued: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.extensionKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.extensionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func isDoneOrCancelled() -> Bool {
        return status == .finished || status == .cancelled
    }
}

extension Array where Element: Equatable {

    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }
}
