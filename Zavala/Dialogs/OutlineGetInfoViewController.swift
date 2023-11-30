//
//  OutlineGetInfoViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/12/21.
//

import UIKit
import VinOutlineKit

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
	
		let createdLabel = NonIntrinsicLabel(frame: CGRect(x: 32.0, y: 0.0, width: 0.0, height: 0.0))
		createdLabel.font = UIFont.systemFont(ofSize: 12.0)
		createdLabel.textColor = UIColor.gray
		if let created = outline?.created {
			createdLabel.text = AppStringAssets.createdOnLabel(date: created)
		} else {
			createdLabel.text = " "
		}
		createdLabel.sizeToFit()
		
		let updatedLabel = NonIntrinsicLabel(frame: CGRect(x: 32.0, y: createdLabel.frame.maxY + 8, width: 0.0, height: 0.0))
		updatedLabel.font = UIFont.systemFont(ofSize: 12.0)
		updatedLabel.textColor = UIColor.gray
		if let updated = outline?.updated {
			updatedLabel.text = AppStringAssets.updatedOnLabel(date: updated)
		} else {
			updatedLabel.text = " "
		}
		updatedLabel.sizeToFit()
		
		let width = max(createdLabel.frame.width, updatedLabel.frame.width)
		let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: updatedLabel.frame.maxY))
		wrapperView.addSubview(createdLabel)
		wrapperView.addSubview(updatedLabel)
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

// MARK: UITextFieldDelegate

extension OutlineGetInfoViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}
