//
//  InputStackView.swift
//  Stash
//
//

import Cocoa

class InputStackView: NSStackView {
    let titleTextField = NSTextField.makeLabel()
    let inputTextField = NSTextField()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    init(title: String, input: String?) {
        super.init(frame: .zero)
        setup()
        
        titleTextField.stringValue = title
        inputTextField.objectValue = input
    }
    
    private func setup() {
        titleTextField.alignment = .right
        inputTextField.isEditable = true
        
        orientation = .horizontal
        addArrangedSubview(titleTextField)
        addArrangedSubview(inputTextField)
        
        NSLayoutConstraint.activate([
            titleTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            inputTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])
    }
    
}
