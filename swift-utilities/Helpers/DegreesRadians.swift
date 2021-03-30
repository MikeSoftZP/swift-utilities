//
//  DegreesRadians.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 24.06.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import UIKit

extension BinaryInteger {
    var toRadians: CGFloat { CGFloat(self) * .pi / 180 }
}

extension FloatingPoint {
    var toRadians: Self { self * .pi / 180 }
    var toDegrees: Self { self * 180 / .pi }
}
