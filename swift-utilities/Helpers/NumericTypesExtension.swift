//
//  NumericTypesExtension.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 24.06.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import UIKit

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Rounds the double to decimal places value
    func floor(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded(.down) / divisor
    }
}

protocol FloatingFormat: CVarArg {}
extension FloatingFormat {
    /// Truncating tail
    func format(decimals: UInt = 2) -> String {
        return String(format: "%.\(decimals)f", self)
    }
}
extension Float: FloatingFormat {}
extension Double: FloatingFormat {}
extension CGFloat: FloatingFormat {}

protocol SizeFormat: BinaryInteger {}
extension SizeFormat {
    func formatBytes(marker: Int = 1024, decimals: UInt = 3) -> String {
        if self == 0 {
            return "0 Bytes"
        }
        
        let dm = decimals > 10 ? 10 : decimals
        let sizes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
        
        let i = Int(floor((log10(Double(self)) / log10(Double(marker)))))
        return String(format: "%.\(dm)f \(sizes[i])", Double(self) / pow(Double(marker), Double(i)))
    }
}
extension Int: SizeFormat {}
extension UInt: SizeFormat {}
extension Int64: SizeFormat {}
extension UInt64: SizeFormat {}
