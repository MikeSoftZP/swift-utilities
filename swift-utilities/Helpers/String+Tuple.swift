//
//  String+Tuple.swift
//  Rivet
//
//  Created by Mike Ponomaryov on 17.11.2020.
//  Copyright © 2020 Mike Ponomaryov. All rights reserved.
//

import Foundation

extension String {
    
    func copyTo<T>(tuple: inout T) {
        
        let tupleSize = MemoryLayout.size(ofValue: tuple)
        let size = min(count, tupleSize)
        var cStr = utf8CString

        withUnsafeMutablePointer(to: &tuple) { (pTuple) in
            let pRawTuple = UnsafeMutableRawPointer(pTuple)
            
            withUnsafePointer(to: &cStr[0]) { (pString) in
                let pRawString = UnsafeRawPointer(pString)
                pRawTuple.copyMemory(from: pRawString, byteCount: size)
            }
        }
    }
}
