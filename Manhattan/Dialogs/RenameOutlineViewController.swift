//
//  RenameOutlineViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/12/20.
//

import UIKit
import Templeton

class RenameOutlineViewController: FormViewController {
	
	var outline: Outline?

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

		nameTextField.text = outline?.name
		nameTextField.addTarget(self, action: #selector(nameTextFieldDidChange), for: .editingChanged)
		nameTextField.delegate = self
		
		updateUI()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		nameTextField.becomeFirstResponder()
	}
	
	@objc func nameTextFieldDidChange(textField: UITextField) {
		updateUI()
	}
	
	@IBAction override func submit(_ sender: Any) {
		guard let outline = outline, let outlineName = nameTextField.text, !outlineName.isEmpty else { return }
		
		outline.rename(to: outlineName) { result in
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

extension RenameOutlineViewController: UITextFieldDelegate {
	
	func updateUI() {
		let isReady = !(nameTextField.text?.isEmpty ?? false)
		addBarButtonItem.isEnabled = isReady
		submitButton.isEnabled = isReady
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}
