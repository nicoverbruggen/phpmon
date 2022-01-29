//
//  ImageGenerator.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
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
        let textRect = CGRect(x: padding, y: 0.5, width: image.size.width, height: image.size.height)
        
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
    
    /**
     The same as before, but also attempts to add an icon to the left.
     */
    public static func textToImageWithIcon(text: String) -> NSImage {
        let textImage = self.textToImage(text: text)
        let iconImage = NSImage(named: "StatusBarPHP")!
        let iconWidthSize = iconImage.size.width
        let divider = iconWidthSize
        
        let imageRect = CGRect(
            x: 0,
            y: 0,
            width: textImage.size.width + divider,
            height: textImage.size.height
        )
        
        let image: NSImage = NSImage(size: imageRect.size)
        image.lockFocus()
        
        let difference = imageRect.size.width - textImage.size.width
        
        textImage.draw(in: imageRect, from: NSRect(
            x: -difference,
            y: 0, width: textImage.size.width + difference,
            height: textImage.size.height
        ), operation: .overlay, fraction: 1)
        
        iconImage.draw(in: imageRect, from: NSRect(x: 0, y: 0, width: imageRect.size.width * 1.6, height: imageRect.size.height * 2.0), operation: .overlay, fraction: 1)
        
        image.unlockFocus()
        return image
    }
    
}
