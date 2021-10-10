//
//  MacRenameTagViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import UIKit
import Templeton

class MacRenameTagViewController: MacFormViewController {
	
	var tagDocuments: TagDocuments?
	
	@IBOutlet weak var tagNameTextField: UITextField!
	@IBOutlet weak var renameButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		renameButton.role = .primary
		NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: tagNameTextField)
		updateUI()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		tagNameTextField.becomeFirstResponder()
	}
	
	@IBAction override func submit(_ sender: Any) {
		guard let tagName = tagNameTextField.text, let tag = tagDocuments?.tag else { return }
		tagDocuments?.account?.renameTag(tag, to: tagName)
		dismiss(animated: true)
	}
	
}

extension MacRenameTagViewController {
	
	@objc private func textDidChange(_ note: Notification) {
		updateUI()
	}
	
	private func updateUI() {
		renameButton.isEnabled = !(tagNameTextField.text?.isEmpty ?? true)
	}
	
}
