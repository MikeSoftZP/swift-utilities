//
//  CameraButton.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 04.06.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import UIKit

@IBDesignable
class CameraButton: UIButton {
    
    private enum Constants {
        static let size = CGSize(width: 66.0, height: 66.0)
        static let outerRingMargin: CGFloat = 3.0
        static let outerRingLineWidth: CGFloat = 6.0
        static let buttonColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        static let circleRect = CGRect(x: 8, y: 8, width: 50, height: 50)
        static let squareRect = CGRect(x: 18, y: 18, width: 30, height: 30)
        static let innerCirclePath = UIBezierPath(roundedRect: Constants.circleRect, cornerRadius: 25)
        static let innerSquarePath = UIBezierPath(roundedRect: squareRect, cornerRadius: 4)
        static let animationDuration = 0.15
    }
    
    private var pathLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    func setup() {
        self.pathLayer.path = self.currentInnerPath().cgPath
        self.pathLayer.strokeColor = nil
        self.pathLayer.fillColor = UIColor.red.cgColor
        self.layer.addSublayer(self.pathLayer)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil,
                                              attribute: .width, multiplier: 1, constant: Constants.size.width))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil,
                                              attribute: .width, multiplier: 1, constant: Constants.size.height))
        
        self.setTitle("", for: .normal)
        
        self.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        self.addTarget(self, action: #selector(touchDown), for: .touchDown)
    }
    
    
    override func prepareForInterfaceBuilder() {
        self.setTitle("", for:UIControl.State.normal)
    }
    
    override var isSelected: Bool {
        didSet {
            let morph = CABasicAnimation(keyPath: "path")
            morph.duration = Constants.animationDuration;
            morph.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            morph.toValue = self.currentInnerPath().cgPath
            morph.fillMode = .forwards
            morph.isRemovedOnCompletion = false
            self.pathLayer.add(morph, forKey: "")
        }
    }
    
    @objc func touchUpInside(sender: UIButton) {
        let colorChange = CABasicAnimation(keyPath: "fillColor")
        colorChange.duration = Constants.animationDuration;
        colorChange.toValue = UIColor.red.cgColor
        colorChange.fillMode = .forwards
        colorChange.isRemovedOnCompletion = false
        colorChange.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        self.pathLayer.add(colorChange, forKey:"darkColor")
        self.isSelected = !self.isSelected
    }
    
    @objc func touchDown(sender: UIButton) {
        let morph = CABasicAnimation(keyPath: "fillColor")
        morph.duration = Constants.animationDuration;
        morph.toValue = Constants.buttonColor.cgColor
        morph.fillMode = .forwards
        morph.isRemovedOnCompletion = false
        morph.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.pathLayer.add(morph, forKey: "")
    }
    
    override func draw(_ rect: CGRect) {
        let size = Constants.size
        let margin = Constants.outerRingMargin
        let ovarRect = CGRect(x: margin, y: margin, width: size.width - 2 * margin, height: size.height - 2 * margin)
        let outerRing = UIBezierPath(ovalIn: ovarRect)
        outerRing.lineWidth = Constants.outerRingLineWidth
        UIColor.white.setStroke()
        outerRing.stroke()
    }
    
    func currentInnerPath() -> UIBezierPath {
        return isSelected ? Constants.innerSquarePath : Constants.innerCirclePath
    }
}
