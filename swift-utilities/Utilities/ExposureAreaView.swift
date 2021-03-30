//
//  ExposureAreaView.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 24.06.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import UIKit

class ExposureAreaView: UIView {
    
    private enum Constants {
        static let lineWidth: CGFloat = 2.0
        static let lineColor = UIColor.white
        static let lineHighlightedColor = UIColor.yellow
        static let knobSize = CGSize(width: 10.0, height: 10.0)
        static let knobPadding: CGFloat = 4.0
        static let knobLinePadding: CGFloat = 12.0
        static let animationDuration: CFTimeInterval = 0.8
        static let animationKey = "flashAnimation"
    }
    
    private var topLinePathLayer = CAShapeLayer()
    private var bottomLinePathLayer = CAShapeLayer()
    private var knobPathLayer = CAShapeLayer()
    
    private var animationInProgress = false
    private var afterAnimationTask: DispatchWorkItem? = nil
    
    var minValue: CGFloat = -1.0 {
           didSet { updatePath() }
       }
    var maxValue: CGFloat = 1.0 {
           didSet { updatePath() }
       }
    var value: CGFloat = 0 {
        didSet { updatePath() }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        updatePath()
        
        layer.addSublayer(topLinePathLayer)
        layer.addSublayer(bottomLinePathLayer)
        layer.addSublayer(knobPathLayer)

//        pathLayer.opacity = 0.0
        isHidden = true
    }
    
    private func updatePath() {
        if abs(maxValue - minValue) < 0.001 || value < minValue || value > maxValue {
            return
        }
        
        let percent = (value - minValue) / (maxValue - minValue)
        let knobSize = Constants.knobSize
        let knobPadding = Constants.knobPadding
        let knobLinePadding = Constants.knobLinePadding
        let activeBounds = bounds.insetBy(dx: 0, dy: knobSize.height / 2 + knobLinePadding)
        let knobCenter = CGPoint(x: activeBounds.midX, y: (1.0 - percent) * (activeBounds.maxY - activeBounds.minY) + activeBounds.minY)
        let knobOrigin = CGPoint(x: knobCenter.x - knobSize.width / 2, y: knobCenter.y - knobSize.height / 2)
        let knobRect = CGRect(origin: knobOrigin, size: knobSize)
        print("percent: = \(percent * 100)")
        
        let lineWidth = Constants.lineWidth
        
        let topLinePath = UIBezierPath()
        topLinePath.lineWidth = lineWidth
        if knobRect.minY - knobLinePadding >= bounds.minY {
            topLinePath.move(to: CGPoint(x: bounds.midX, y: bounds.minY))
            topLinePath.addLine(to: CGPoint(x: bounds.midX, y: knobCenter.y - knobSize.height / 2 - knobLinePadding))
        }
        
        topLinePathLayer.strokeColor = Constants.lineColor.cgColor
        topLinePathLayer.fillColor = Constants.lineColor.cgColor
        topLinePathLayer.path = topLinePath.cgPath
        
        
        let bottomLinePath = UIBezierPath()
        bottomLinePath.lineWidth = lineWidth
        if knobRect.maxY + knobLinePadding < bounds.maxY {
            bottomLinePath.move(to: CGPoint(x: bounds.midX, y: bounds.maxY))
            bottomLinePath.addLine(to: CGPoint(x: bounds.midX, y: knobCenter.y + knobSize.height / 2 + knobLinePadding))
        }
        
        bottomLinePathLayer.strokeColor = Constants.lineColor.cgColor
        bottomLinePathLayer.fillColor = Constants.lineColor.cgColor
        bottomLinePathLayer.path = bottomLinePath.cgPath
        
        
        
        let knobPath = UIBezierPath(ovalIn: knobRect)

        for i in 0...360 where i % 45 == 0 {
            let angle = CGFloat(i.toRadians)
            let x = knobCenter.x + (knobPadding + knobSize.width / 2) * sin(angle)
            let y = knobCenter.y + (knobPadding + knobSize.width / 2) * cos(angle)
            let tx = knobCenter.x + (2 * knobPadding + knobSize.width / 2) * sin(angle)
            let ty = knobCenter.y + (2 * knobPadding + knobSize.width / 2) * cos(angle)
            
            knobPath.move(to: CGPoint(x: x, y: y))
            knobPath.addLine(to: CGPoint(x: tx, y: ty))
        }
        
        knobPathLayer.strokeColor = Constants.lineColor.cgColor
        knobPathLayer.fillColor = Constants.lineColor.cgColor
        knobPathLayer.path = knobPath.cgPath
    }
}
