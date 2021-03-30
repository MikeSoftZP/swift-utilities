//
//  Global.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 13.07.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import Foundation

@discardableResult
func synchronized<T>(_ lock: Any, _ closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try closure()
}

func sleepDelay(sec: Double) {
    let second: UInt32 = 1000000
    let delay: Double = sec * Double(second)
    let inverval = UInt32(delay)
    usleep(inverval)
}

extension FileManager {
    
    static func documentsPath(for filepath: String) -> URL? {
        let fileManager = self.default
        guard let docsBaseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
            let fileURL = docsBaseURL.appendingPathComponent(filepath) as URL? else { return nil }
        return fileURL
    }
}
