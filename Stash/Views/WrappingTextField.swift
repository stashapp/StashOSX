//
//  WrappingTextField.swift
//  Stash
//
//

import Cocoa

/*
 http://stackoverflow.com/questions/35356225/nstextfieldcells-cellsizeforbounds-doesnt-match-wrapping-behavior
 http://stackoverflow.com/questions/17147366/auto-resizing-nstokenfield-with-constraint-based-layout?noredirect=1&lq=1
 http://stackoverflow.com/questions/14107385/getting-a-nstextfield-to-grow-with-the-text-in-auto-layout/14111406#14111406
 */

class WrappingTextField: NSTextField {
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        invalidateIntrinsicContentSize()
        validateEditing()
    }
    
    open override var intrinsicContentSize: NSSize {
        guard let cell = cell else { return super.intrinsicContentSize }
        
        let size = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: bounds.size.width, height: 1000))
        return NSSize(width: NSViewNoIntrinsicMetric, height: size.height)
    }
}
