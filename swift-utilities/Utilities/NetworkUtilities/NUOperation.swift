//
//  NUOperation.swift
//  PhotoBackup
//
//  Created by Mike Ponomaryov on 13.07.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import Foundation

typealias NUOperationExecutionBlock = (_ operation: NUOperation) -> Void
typealias NUOperationCompletionBlock = (_ operation: NUOperation) -> Void
typealias NUOperationCancellationBlock = (_ operation: NUOperation) -> Void

class NUOperation: Equatable {
    
    enum Status: Int {
        case idle, executing, finished, cancelled
    }
    
    var identifier: String
    var associatedObject: Any?
    
    var status: Status {
        get { return _status }
        set { updateStatus(newValue) }
    }
    
//    override var hash: Int {
//        return identifier.hashValue
//    }
    
    private var _status = Status.idle
    private var executionBlock: NUOperationExecutionBlock?
    private var completionBlock: NUOperationCompletionBlock?
    private var cancellationBlock: NUOperationCancellationBlock?
    
    var queueCompletionBlock: NUOperationCompletionBlock?
    
    private var wasCancelled = false
    private var wasFinished = false
    
    init(block: NUOperationExecutionBlock?, completion: NUOperationCompletionBlock? = nil, cancellation: NUOperationCancellationBlock? = nil) {
        identifier = UUID().uuidString
        
        executionBlock = block
        completionBlock = completion
        cancellationBlock = cancellation
    }
    
    func cancel() {
        cancellationBlock = nil  // TODO: cancellation block not always invoking even if commented
        completionBlock = nil
        executionBlock = nil
        status = .cancelled
    }

    private func updateStatus(_ status: Status) {
        if _status != status {
            DispatchQueue.main.syncSafely {
                _status = status
            }
                
            switch status {
            case .idle:
                break
            case .executing:
                if !wasFinished && !wasCancelled {
                    executionBlock?(self)
                    executionBlock = nil
                }
            case .finished:
                if !wasFinished && !wasCancelled {
                    wasFinished = true
                    self.completionBlock?(self)
                    self.completionBlock = nil
                    DispatchQueue.main.syncSafely {
                        self.queueCompletionBlock?(self)
                        self.queueCompletionBlock = nil
                    }
                }
            case .cancelled:
                if !wasFinished && !wasCancelled {
                    wasCancelled = true
                    completionBlock = nil
                    self.cancellationBlock?(self)
                    self.cancellationBlock = nil
                    DispatchQueue.main.syncSafely {
                        self.queueCompletionBlock?(self)
                        self.queueCompletionBlock = nil
                    }
                }
            }
        }
    }
    
//    override func isEqual(_ object: Any?) -> Bool {
//        guard let obj = object as? NUOperation else { return false }
//        return identifier == obj.identifier
//    }
    
    static func == (lhs: NUOperation, rhs: NUOperation) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    static func != (lhs: NUOperation, rhs: NUOperation) -> Bool {
        return lhs.identifier != rhs.identifier
    }
}

extension NUOperation: NSCopying {

    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}
