//
//  LinkViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 12/17/20.
//

import UIKit
import RSCore
import Templeton

protocol LinkViewControllerDelegate: AnyObject {
	func updateLink(_: LinkViewController, cursorCoordinates: CursorCoordinates, link: String?, range: NSRange)
}

class LinkViewController: FormViewController {

	static let preferredContentSize = CGSize(width: 400, height: 150)

	weak var delegate: LinkViewControllerDelegate?
	var cursorCoordinates: CursorCoordinates?
	var link: String?
	var range: NSRange?
	
	@IBOutlet weak var nameTextField: UITextField!
	
	@IBOutlet weak var addBarButtonItem: UIBarButtonItem!

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var submitButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		if traitCollection.userInterfaceIdiom == .mac {
			nameTextField.placeholder = nil
			nameTextField.borderStyle = .bezel
			navigationController?.setNavigationBarHidden(true, animated: false)
			submitButton.role = .primary
		} else {
			nameLabel.isHidden = true
			cancelButton.isHidden = true
			submitButton.isHidden = true
		}

		nameTextField.text = link
		nameTextField.delegate = self
	}
	
	override func viewDidAppear(_ animated: Bool) {
		nameTextField.becomeFirstResponder()
	}
	
	@IBAction override func submit(_ sender: Any) {
		guard let cursorCoordinates = cursorCoordinates, let range = range else { return }
		
		if let newLink = nameTextField.text, !newLink.trimmingWhitespace.isEmpty {
			delegate?.updateLink(self, cursorCoordinates: cursorCoordinates, link: newLink.trimmingWhitespace, range: range)
		} else {
			delegate?.updateLink(self, cursorCoordinates: cursorCoordinates, link: nil, range: range)
		}
		
		dismiss(animated: true)
	}
	
}

extension LinkViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}
