//
//  WrappingTokenField.swift
//  Stash
//
//

import Cocoa

class WrappingTokenField: NSTokenField {
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        invalidateIntrinsicContentSize()
        validateEditing()
    }
    
    open override var intrinsicContentSize: NSSize {
        guard let cell = cell else { return super.intrinsicContentSize }
        
        let size = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: bounds.size.width, height: 1000))
        return NSSize(width: NSViewNoIntrinsicMetric, height: size.height + 2)
    }
}
