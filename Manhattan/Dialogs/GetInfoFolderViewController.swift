//
//  GetInfoFolderViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/12/20.
//

import Foundation

import UIKit
import Templeton

class GetInfoFolderViewController: FormViewController {

	static let preferredContentSize = CGSize(width: 400, height: 200)

	var folder: Folder?
	
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

		nameTextField.text = folder?.name
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
		guard let folder = folder, let folderName = nameTextField.text, !folderName.isEmpty else { return	}
		folder.update(name: folderName)
		dismiss(animated: true)
	}
	
	func updateUI() {
		let isReady = !(nameTextField.text?.isEmpty ?? false)
		addBarButtonItem.isEnabled = isReady
		submitButton.isEnabled = isReady
	}
	
}

extension GetInfoFolderViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}
