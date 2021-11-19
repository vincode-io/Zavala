//
//  OutlineGetInfoViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/10/21.
//

import UIKit
import Templeton

class MacOutlineGetInfoViewController: MacFormViewController {

	weak var outline: Outline?
	
	@IBOutlet var ownerBackgroundView: UIView!
	@IBOutlet weak var ownerNameTextField: UITextField!
	@IBOutlet weak var ownerEmailTextField: UITextField!
	@IBOutlet weak var ownerURLTextField: UITextField!
	
	@IBOutlet weak var createdLabel: UILabel!
	@IBOutlet weak var updatedLabel: UILabel!
	
	@IBOutlet weak var macCancelButton: UIButton!
	@IBOutlet weak var macSubmitButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		macSubmitButton.role = .primary

		ownerBackgroundView.layer.backgroundColor = UIColor.quaternarySystemFill.cgColor
		ownerBackgroundView.layer.cornerRadius = 5
		ownerBackgroundView.layer.borderWidth = 1
		ownerBackgroundView.layer.borderColor = UIColor.quaternaryLabel.cgColor
		
		ownerNameTextField.text = outline?.ownerName
		ownerEmailTextField.text = outline?.ownerEmail
		ownerURLTextField.text = outline?.ownerURL

		ownerNameTextField.delegate = self
		ownerEmailTextField.delegate = self
		ownerURLTextField.delegate = self

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none

		let timeFormatter = DateFormatter()
		timeFormatter.dateStyle = .none
		timeFormatter.timeStyle = .short
	
		if let created = outline?.created {
			createdLabel.text = L10n.createdOn(dateFormatter.string(from: created), timeFormatter.string(from: created))
		} else {
			createdLabel.text = " "
		}
		
		if let updated = outline?.updated {
			updatedLabel.text = L10n.updatedOn(dateFormatter.string(from: updated), timeFormatter.string(from: updated))
		} else {
			updatedLabel.text = " "
		}
		
		if (outline?.ownerName?.isEmpty ?? true) && (outline?.ownerEmail?.isEmpty ?? true) && (outline?.ownerURL?.isEmpty ?? true) {
			macSubmitButton.setTitle(L10n.add, for: .normal)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		ownerNameTextField.becomeFirstResponder()
	}

	@IBAction func submit(_ sender: Any) {
		submitAndDismiss()
	}
	
}

// MARK: UITextFieldDelegate

extension MacOutlineGetInfoViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		submitAndDismiss()
		return false
	}
	
}

// MARK: Helpers

private extension MacOutlineGetInfoViewController {
	
	func submitAndDismiss() {
		outline?.update(ownerName: ownerNameTextField.text, ownerEmail: ownerEmailTextField.text, ownerURL: ownerURLTextField.text)
		dismiss(animated: true)
	}
	
}
