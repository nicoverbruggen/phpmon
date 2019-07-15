//
//  ImageGenerator.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class MenuBarImageGenerator {
    
    /**
     Takes a string and converts it to an image that can be displayed in the menu bar.
     The width of the NSImage depends on the length of the text.
     */
    public static func textToImage(text: String) -> NSImage {
        
        let font = NSFont.systemFont(ofSize: 14, weight: .medium)
        
        let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let textFontAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: NSColor.black,
            NSAttributedString.Key.paragraphStyle: textStyle
        ]
        
        let padding : CGFloat = 2.0;
        
        // Create an attributed string so we'll know how wide the item will need to be
        let attributedString = NSAttributedString(string: text, attributes: textFontAttributes)
        let textSize = attributedString.size()
        
        // Add padding to the width of the menu bar item
        let size = NSSize(width: textSize.width + (2 * padding), height: textSize.height)
        let image = NSImage(size: size)
        
        // Set the image rect with the appropriate dimensions
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        // Position the text inside the image rect
        let textRect = CGRect(x: padding, y: 0, width: image.size.width, height: image.size.height)
        
        let targetImage: NSImage = NSImage(size: image.size)
        let rep: NSBitmapImageRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width),
            pixelsHigh: Int(image.size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSColorSpaceName.calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        
        targetImage.addRepresentation(rep)
        targetImage.lockFocus()
        
        image.draw(in: imageRect)
        text.draw(in: textRect, withAttributes: textFontAttributes)
        
        targetImage.unlockFocus()
        return targetImage
    }
    
}
