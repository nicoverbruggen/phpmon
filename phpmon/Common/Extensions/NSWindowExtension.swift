//
//  NSWindowExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

extension NSWindow {

    /**
     Shakes a window. Inspired by: http://blog.ericd.net/2016/09/30/shaking-a-macos-window/
     */
    func shake() {
        let numberOfShakes = 3, durationOfShake = 0.2, vigourOfShake: CGFloat = 0.03

        let frame: CGRect = self.frame
        let shakeAnimation: CAKeyframeAnimation  = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move( to: CGPoint(x: frame.minX, y: frame.minY))

        for _ in 0...numberOfShakes-1 {
            shakePath.addLine(to: CGPoint(x: frame.minX - frame.size.width * vigourOfShake, y: frame.minY))
            shakePath.addLine(to: CGPoint(x: frame.minX + frame.size.width * vigourOfShake, y: frame.minY))
        }

        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = durationOfShake

        self.animations = ["frameOrigin": shakeAnimation]
        self.animator().setFrameOrigin(self.frame.origin)
    }
}
