//
//  NSTextField+Helpers.swift
//  Stash
//
//

import Cocoa

extension NSTextField {
    static func makeLabel(_ string: String = "") -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = string
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        return textField
    }
}
