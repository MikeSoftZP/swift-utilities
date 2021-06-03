//
//  MemoryHolder.swift
//  PhotoBackup
//
//  Created by Mike Ponomaryov on 13.07.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import Foundation

class MemoryHolder {
    static let shared = MemoryHolder()
    
    private var objects: [AnyObject]
    
    private init() {
        objects = [AnyObject]()
    }
    
    func hold(object: AnyObject) {
        if !objects.contains(where: { $0 === object}) {
            objects.append(object)
        }
    }
    func unhold(object: AnyObject) {
        objects.removeAll(where: { $0 === object })
    }
}
