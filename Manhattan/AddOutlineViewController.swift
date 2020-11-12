//
//  AddOutlineViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/11/20.
//

import UIKit
import Templeton

class AddOutlineViewController: FormViewController {

	@IBOutlet weak var addBarButtonItem: UIBarButtonItem!
	
	@IBOutlet weak var nameTextField: UITextField!
	
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

		nameTextField.addTarget(self, action: #selector(nameTextFieldDidChange), for: .editingChanged)
		nameTextField.delegate = self
	}
	
	override func viewDidAppear(_ animated: Bool) {
		nameTextField.becomeFirstResponder()
	}
	
	@objc func nameTextFieldDidChange(textField: UITextField) {
		let isReady = !(nameTextField.text?.isEmpty ?? false)
		addBarButtonItem.isEnabled = isReady
		submitButton.isEnabled = isReady
	}
	
	@IBAction override func submit(_ sender: Any) {

		guard let outlineName = nameTextField.text, !outlineName.isEmpty else {
			return
		}
		
		guard let folder = AccountManager.shared.findAccount(accountID: AccountType.local.rawValue)?.folders?.first else { return }
		
		folder.account?.createOutline(name: outlineName, folder: folder) { result in
			switch result {
			case .success:
				self.dismiss(animated: true)
			case .failure(let error):
				self.presentError(error)
				self.dismiss(animated: true)
			}
		}
		
	}
	
}

extension AddOutlineViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}
