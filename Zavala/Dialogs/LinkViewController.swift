//
//  LinkViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/14/21.
//

import UIKit
import Templeton

protocol LinkViewControllerDelegate: AnyObject {
	func updateLink(cursorCoordinates: CursorCoordinates, text: String, link: String?, range: NSRange)
}

class LinkViewController: UITableViewController {

	@IBOutlet weak var textTextField: UITextField!
	@IBOutlet weak var linkTextField: UITextField!
	
	weak var delegate: LinkViewControllerDelegate?
	var cursorCoordinates: CursorCoordinates?
	var text: String?
	var link: String?
	var range: NSRange?

	override func viewDidLoad() {
        super.viewDidLoad()
		textTextField.text = text
		textTextField.delegate = self
		linkTextField.text = link
		linkTextField.delegate = self
    }

	override func viewDidAppear(_ animated: Bool) {
		textTextField.becomeFirstResponder()
	}

	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func submit(_ sender: Any) {
		guard let cursorCoordinates = cursorCoordinates, let range = range else { return }
		
		let text = textTextField.text?.trimmingWhitespace ?? ""
		if let newLink = linkTextField.text, !newLink.trimmingWhitespace.isEmpty {
			delegate?.updateLink(cursorCoordinates: cursorCoordinates, text: text, link: newLink.trimmingWhitespace, range: range)
		} else {
			delegate?.updateLink(cursorCoordinates: cursorCoordinates, text: text, link: nil, range: range)
		}
		
		dismiss(animated: true)
	}
}

extension LinkViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}
	
}
