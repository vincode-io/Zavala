//
//  RenameTagViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import UIKit
import VinOutlineKit

class RenameTagViewController: UITableViewController {

	var tagDocuments: TagDocuments?
	
	@IBOutlet weak var renameBarButtonItem: UIBarButtonItem!
	@IBOutlet weak var tagNameTextField: UITextField!
	
	override func viewDidLoad() {
        super.viewDidLoad()

		tagNameTextField.delegate = self
		NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: tagNameTextField)
		updateUI()
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		tagNameTextField.text = tagDocuments?.tag?.name
		tagNameTextField.becomeFirstResponder()
		updateUI()
	}
	
	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func submit(_ sender: Any) {
		guard let tagName = tagNameTextField.text, let tag = tagDocuments?.tag else { return }
		
		do {
			try tagDocuments?.account?.renameTag(tag, to: tagName)
			dismiss(animated: true)
		} catch {
			presentError(error)
		}
	}
	
}

// MARK: UITextFieldDelegate

extension RenameTagViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}
	
}

// MARK: Helpers

private extension RenameTagViewController {
	
	@objc func textDidChange(_ note: Notification) {
		updateUI()
	}
	
	func updateUI() {
		renameBarButtonItem.isEnabled = !(tagNameTextField.text?.isEmpty ?? true)
	}
	
}
