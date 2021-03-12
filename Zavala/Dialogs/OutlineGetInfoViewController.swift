//
//  OutlineGetInfoViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/10/21.
//

import UIKit
import Templeton

class OutlineGetInfoViewController: FormViewController {

	static let preferredContentSize = CGSize(width: 400, height: 190)

	weak var outline: Outline?
	
	@IBOutlet weak var ownerNameLabel: UILabel!
	@IBOutlet weak var ownerNameTextField: UITextField!
	@IBOutlet weak var ownerEmailLabel: UILabel!
	@IBOutlet weak var ownerEmailTextField: UITextField!
	@IBOutlet weak var ownerURLLabel: UILabel!
	@IBOutlet weak var ownerURLTextField: UITextField!
	
	@IBOutlet weak var createdSpacer: UILabel!
	@IBOutlet weak var createdLabel: UILabel!
	@IBOutlet weak var updatedSpacer: UILabel!
	@IBOutlet weak var updatedLabel: UILabel!
	
	@IBOutlet weak var macCancelButton: UIButton!
	@IBOutlet weak var macSubmitButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		if traitCollection.userInterfaceIdiom == .mac {
			ownerNameTextField.placeholder = nil
			ownerNameTextField.borderStyle = .bezel
			ownerEmailTextField.placeholder = nil
			ownerEmailTextField.borderStyle = .bezel
			ownerURLTextField.placeholder = nil
			ownerURLTextField.borderStyle = .bezel
			macSubmitButton.role = .primary
		} else {
			ownerNameLabel.isHidden = true
			ownerEmailLabel.isHidden = true
			ownerURLLabel.isHidden = true
			createdSpacer.isHidden = true
			updatedSpacer.isHidden = true
			macCancelButton.isHidden = true
			macSubmitButton.isHidden = true
		}

		ownerNameTextField.text = outline?.ownerName
		ownerEmailTextField.text = outline?.ownerEmail
		ownerURLTextField.text = outline?.ownerURL

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
	}
	
	override func viewDidAppear(_ animated: Bool) {
		ownerNameTextField.becomeFirstResponder()
	}

	@IBAction override func submit(_ sender: Any) {
		outline?.update(ownerName: ownerNameTextField.text, ownerEmail: ownerEmailTextField.text, ownerURL: ownerURLTextField.text)
		dismiss(animated: true)
	}
	
}

extension OutlineGetInfoViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}
