//
//  OutlineGetInfoViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/12/21.
//

import UIKit
import Templeton

class OutlineGetInfoViewController: UITableViewController {

	weak var outline: Outline?
	
	@IBOutlet weak var ownerNameTextField: UITextField!
	@IBOutlet weak var ownerEmailTextField: UITextField!
	@IBOutlet weak var ownerURLTextField: UITextField!
	
	override func viewDidLoad() {
        super.viewDidLoad()

		navigationItem.title = outline?.title

		ownerNameTextField.delegate = self
		ownerEmailTextField.delegate = self
		ownerURLTextField.delegate = self

		ownerNameTextField.text = outline?.ownerName
		ownerEmailTextField.text = outline?.ownerEmail
		ownerURLTextField.text = outline?.ownerURL
	
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none

		let timeFormatter = DateFormatter()
		timeFormatter.dateStyle = .none
		timeFormatter.timeStyle = .short
	
		let createLabel = NonIntrinsicLabel(frame: CGRect(x: 32.0, y: 0.0, width: 0.0, height: 0.0))
		createLabel.font = UIFont.systemFont(ofSize: 12.0)
		createLabel.textColor = UIColor.gray
		if let created = outline?.created {
			createLabel.text = L10n.createdOn(dateFormatter.string(from: created), timeFormatter.string(from: created))
		} else {
			createLabel.text = " "
		}
		createLabel.sizeToFit()
		
		let updateLabel = NonIntrinsicLabel(frame: CGRect(x: 32.0, y: createLabel.frame.maxY + 8, width: 0.0, height: 0.0))
		updateLabel.font = UIFont.systemFont(ofSize: 12.0)
		updateLabel.textColor = UIColor.gray
		if let updated = outline?.updated {
			updateLabel.text = L10n.updatedOn(dateFormatter.string(from: updated), timeFormatter.string(from: updated))
		} else {
			updateLabel.text = " "
		}
		updateLabel.sizeToFit()
		
		let width = max(createLabel.frame.width, updateLabel.frame.width)
		let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: updateLabel.frame.maxY))
		wrapperView.addSubview(createLabel)
		wrapperView.addSubview(updateLabel)
		tableView.tableFooterView = wrapperView
	}

	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func submit(_ sender: Any) {
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
