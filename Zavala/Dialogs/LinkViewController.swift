//
//  LinkViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/14/21.
//

import UIKit
import Templeton

protocol LinkViewControllerDelegate: AnyObject {
	func createOutline(title: String) -> Outline?
	func updateLink(cursorCoordinates: CursorCoordinates, text: String, link: String?, range: NSRange)
}

class LinkViewController: UITableViewController {

	override var keyCommands: [UIKeyCommand]? {
		[
			UIKeyCommand(action: #selector(arrowUp(_:)), input: UIKeyCommand.inputUpArrow),
			UIKeyCommand(action: #selector(arrowDown(_:)), input: UIKeyCommand.inputDownArrow)
		]
	}

	@IBOutlet weak var addOutlineBarButtonItem: UIBarButtonItem!
	@IBOutlet weak var textTextField: SearchTextField!
	@IBOutlet weak var linkTextField: UITextField!
	
	weak var delegate: LinkViewControllerDelegate?
	var cursorCoordinates: CursorCoordinates?
	var text: String?
	var link: String?
	var range: NSRange?
	
	let textTextFieldDelegate = TextTextFieldDelegate()
	let linkTextFieldDelegate = LinkTextFieldDelegate()

	override func viewDidLoad() {
        super.viewDidLoad()
		textTextField.text = text
		textTextField.delegate = textTextFieldDelegate
		linkTextField.text = link
		linkTextField.delegate = linkTextFieldDelegate

		textTextField.itemSelectionHandler = { [weak self] (filteredResults: [SearchTextFieldItem], index: Int) in
			guard let self = self, let documentID = filteredResults[index].associatedObject as? EntityID else {
				return
			}
			self.textTextField.text = filteredResults[index].title
			self.linkTextField.text = documentID.url?.absoluteString ?? ""
			self.updateUI()
		}
		
		let searchItems = AccountManager.shared.activeDocuments.map { SearchTextFieldItem(title: $0.title ?? "", associatedObject: $0.id) }
		textTextField.filterItems(searchItems)

		NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: textTextField)
		NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: linkTextField)

		updateUI()
	}

	override func viewDidAppear(_ animated: Bool) {
		if textTextField.text?.isEmpty ?? true {
			textTextField.becomeFirstResponder()
		} else {
			linkTextField.becomeFirstResponder()
		}
	}

	@objc func arrowUp(_ sender: Any) {
		textTextField.selectAbove()
	}

	@objc func arrowDown(_ sender: Any) {
		textTextField.selectBelow()
	}

	@IBAction func addOutline(_ sender: Any) {
		guard let outlineTitle = textTextField.text else { return }
		let outline = delegate?.createOutline(title: outlineTitle)
		linkTextField.text = outline?.id.url?.absoluteString ?? ""
		submitAndDismiss()
	}
	
	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func submit(_ sender: Any) {
		submitAndDismiss()
	}
}

// MARK: UITextFieldDelegate

class TextTextFieldDelegate: NSObject, UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let searchTextField = textField as? SearchTextField else { return false }
		if searchTextField.isSelecting {
			searchTextField.activateSelection()
		} else {
			searchTextField.resignFirstResponder()
		}
		return false
	}
	
}

// MARK: UITextFieldDelegate

class LinkTextFieldDelegate: NSObject, UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}
	
}

// MARK: Helpers

private extension LinkViewController {
	
	@objc func textDidChange(_ note: Notification) {
		updateUI()
	}
	
	func updateUI() {
		addOutlineBarButtonItem.isEnabled = !(textTextField.text?.isEmpty ?? true) && (linkTextField.text?.isEmpty ?? true)
	}
	
	func submitAndDismiss() {
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
