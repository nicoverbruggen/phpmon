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

        let padding: CGFloat = 2.0

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

        let representation: NSBitmapImageRep = NSBitmapImageRep(
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

        targetImage.addRepresentation(representation)
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

        // We'll start out with the image containing the text
        let textImage = self.textToImage(text: text)

        // Then we'll fetch the image we want on the left
        var iconType = Preferences.preferences[.iconTypeToDisplay] as? String
        if iconType == nil {
            Log.warn("Invalid icon type found, using the default")
            iconType = MenuBarIcon.iconPhp.rawValue
        }

        let iconImage = NSImage(named: "MenuBar_\(iconType!)")!

        // We'll need to reference the width of the icon a bunch of times
        let iconWidthSize = iconImage.size.width

        // There will also be an additional divider between the image and the text (image)
        let divider: CGFloat = 3

        // Use a fixed size for the height of the menu bar (18pt)
        let imageRect = CGRect(
            x: 0,
            y: 0,
            width: textImage.size.width + iconWidthSize + divider,
            height: 18
        )

        // Create a new image, we'll draw the text and our icon in there
        let image: NSImage = NSImage(size: imageRect.size)
        image.lockFocus()

        // Calculate the offset between the image and the text
        let offset = imageRect.size.width - textImage.size.width

        // Draw the text with a negative x offset (so there is room on the left for the icon)
        textImage.draw(
            in: imageRect,
            from: NSRect(
                x: -offset,
                y: 0,
                width: textImage.size.width + offset,
                height: textImage.size.height
            ),
            operation: .overlay,
            fraction: 1
        )

        // Draw the icon directly in the left of the imageRect (where we left space)
        iconImage.draw(
            in: imageRect,
            from: NSRect(
                x: 0,
                y: 0,
                width: imageRect.size.width,
                height: imageRect.size.height
            ),
            operation: .overlay,
            fraction: 1
        )

        // We're done with this image
        image.unlockFocus()

        return image
    }

}
