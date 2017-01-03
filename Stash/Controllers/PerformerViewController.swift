//
//  PerformerViewController.swift
//  Stash
//
//

import Cocoa

class PerformerViewController: NSViewController {
    static func present(from presentingViewController: NSViewController, performer: Performer, callback: @escaping () -> Void) {
        guard let performerViewController = PerformerViewController(performer: performer) else { return }
        performerViewController.callback = callback
        presentingViewController.presentViewControllerAsSheet(performerViewController)
    }
    
    let containerStackView = NSStackView()
    let closeButton = NSButton(title: "Close", target: self, action: #selector(tappedCloseButton(_:)))
    
    weak var nameTextField: NSTextField?
    
    let performer: Performer
    var callback: (() -> Void)? = nil
    
    init?(performer: Performer) {
        self.performer = performer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nameStackView = InputStackView(title: "Name:", input: performer.name)
        
        nameTextField = nameStackView.inputTextField
        
        let objController = NSObjectController(content: performer)
        nameStackView.inputTextField.bind(NSValueBinding, to: objController, withKeyPath: "content.name", options: nil)
        
//        nameStackView.inputTextField.bind(NSValueBinding, to: performer, withKeyPath: #keyPath(Performer.name), options: nil)
//        nameStackView.inputTextField.bind(NSValueBinding, to: performer, withKeyPath: #keyPath(Performer.name), options: [NSContinuouslyUpdatesValueBindingOption: true])
        
        containerStackView.orientation = .vertical
        containerStackView.addArrangedSubview(nameStackView)
        containerStackView.addArrangedSubview(closeButton)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerStackView)
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            containerStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            containerStackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            containerStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        ])
    }
    
    @objc private func tappedCloseButton(_ sender: NSButton) {
        dismiss(sender)
        
//        if performer.name
        callback?()
    }
    
}
