//
//  DispatchQueue+Thread.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 23.12.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import Foundation

extension DispatchQueue {
    
    func syncSafely(block:() -> Void) {
        if self == DispatchQueue.main {
            // the only reason of this check - is performance (not comparing strings)
            syncOnMainSafely(block: block)
        } else {
            let queueLabel = __dispatch_queue_get_label(self)
            let runtimeQueueLabel = __dispatch_queue_get_label(nil)
            let queueLabelText = String(cString: queueLabel, encoding: .utf8)
            let runtimeQueueLabelText = String(cString: runtimeQueueLabel, encoding: .utf8)
            let needsDispatch = queueLabelText != runtimeQueueLabelText

            if !needsDispatch {
                block()
            } else {
                self.sync(execute: block)
            }
        }
    }
    
    private func syncOnMainSafely(block:() -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            self.sync(execute: block)
        }
    }
}
