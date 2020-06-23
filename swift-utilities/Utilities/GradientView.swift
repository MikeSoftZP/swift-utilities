//
//  GradientView.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 27.04.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import UIKit

@IBDesignable
class GradientView: UIView {
    
    enum Constants {
        static let bgGradientAngle: CGFloat = 0.0
        static let bgColorsLocations: [NSNumber] = [0.0, 1.0]
        static let bgColors = [UIColor(rgb: 0x1a273a).cgColor, UIColor(rgb: 0x101214).cgColor]
    }
    
    private let gradientLayer = CAGradientLayer()
    var angle: CGFloat = Constants.bgGradientAngle {
        didSet {
            updateGradient()
        }
    }
    var colors: [CGColor] = Constants.bgColors {
        didSet {
            updateGradient()
        }
    }
    var locations: [NSNumber] = Constants.bgColorsLocations {
        didSet {
            updateGradient()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupGradient()
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override var frame: CGRect {
        didSet {
            gradientLayer.frame = bounds
        }
    }
    
    func setupGradient() {

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        updateGradient()
        
        layer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func updateGradient() {
        let x = angle / 360.0
        let a = pow(sin(2.0 * CGFloat.pi * ((x + 0.75) / 2.0)), 2.0)
        let b = pow(sin(2.0 * CGFloat.pi * ((x + 0.0) / 2.0)), 2.0)
        let c = pow(sin(2.0 * CGFloat.pi * ((x + 0.25) / 2.0)), 2.0)
        let d = pow(sin(2.0 * CGFloat.pi * ((x + 0.5) / 2.0)), 2.0)

        gradientLayer.startPoint = CGPoint(x: a, y: b)
        gradientLayer.endPoint = CGPoint(x: c, y: d)
        gradientLayer.colors = colors
        gradientLayer.locations = locations
    }
}
