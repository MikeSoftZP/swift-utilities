//
//  UIColor+Hex.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 19.06.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import UIKit

extension UIColor {
    
   convenience init(r: Int, g: Int, b: Int, a: CGFloat = 1.0) {
        let r = min(255.0, max(0.0, CGFloat(r))) / 255.0
        let g = min(255, max(0, CGFloat(g))) / 255.0
        let b = min(255, max(0, CGFloat(b))) / 255.0
        let a = min(1.0, max(0, a))

        self.init(red: r, green: g, blue: b, alpha: a)
   }

    convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(r: (rgb >> 16) & 0xFF, g: (rgb >> 8) & 0xFF, b: rgb & 0xFF, a: a)
    }
    
    convenience init(hex: String) {
        var hexString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (hexString.hasPrefix("#")) {
            hexString.remove(at: hexString.startIndex)
        }
        
        var alpha: CGFloat = 1.0
        
        if (hexString.count == 8) {
            var alphaValue: UInt64 = 0
            let alphaString = String(hexString.suffix(2))
            hexString = String(hexString.prefix(6))
            
            Scanner(string: alphaString).scanHexInt64(&alphaValue)
            
            alpha = CGFloat(alphaValue & 0xFF) / 255.0
        }

        assert(hexString.count == 6, "\(hex) is invalid hex parameter")

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        self.init(rgb: Int(rgbValue), a: alpha)
    }
}
