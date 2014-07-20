//
//  RoundedButton.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/18/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  RoundedButton.h and RoundedButton.m
//  Created by Pasin Suriyentrakorn on 4/8/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.

// Does not work; not even needed!
// For some reason, in Swift beta 3, Apple set the QuartzCore calls as Obj-C only
// therefore no CAShapeLayer()
//
// The easier way to do it is to set user-defined properties on the buttons in the storyboard.
// Set self.layer.cornerRadius to half the width; set self.layer.maskToBounds to true.

import UIKit

class RoundedButton: UIButton {

    init(frame: CGRect) {
        super.init(frame: frame)
        // Initialization code
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */
    
    override var frame: CGRect {
    set {
        super.frame = frame
        if !self.layer.mask {
            var maskLayer = CALayer()
            maskLayer.bounds = frame
            maskLayer.path = CGPathCreateWithEllipseInRect(frame, nil )
            maskLayer.position = CGPointMake(frame.size.width/2, frame.size.height/2)
            maskLayer.shouldRasterize = true
            maskLayer.rasterizationScale = UIScreen.mainScreen().scale
            
            self.layer.mask = maskLayer
        }
    }
    get {
        return self.frame
    }
    }

}
