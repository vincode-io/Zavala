//
//  OutlineGetInfoViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/10/21.
//

import UIKit

class OutlineGetInfoViewController: FormViewController {

	static let preferredContentSize = CGSize(width: 400, height: 200)

	override func viewDidLoad() {
		super.viewDidLoad()
	
//		if traitCollection.userInterfaceIdiom == .mac {
//			nameTextField.placeholder = nil
//			nameTextField.borderStyle = .bezel
//			submitButton.role = .primary
//		} else {
//			nameLabel.isHidden = true
//			cancelButton.isHidden = true
//			submitButton.isHidden = true
//		}

	}
	
	override func viewDidAppear(_ animated: Bool) {
//		nameTextField.becomeFirstResponder()
	}
	
	@IBAction override func submit(_ sender: Any) {
		dismiss(animated: true)
	}
	
}

extension OutlineGetInfoViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}
