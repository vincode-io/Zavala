//
//  LinkViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 12/17/20.
//

import UIKit
import RSCore
import Templeton

class MacLinkViewController: UIViewController {

	override var keyCommands: [UIKeyCommand]? {
		[
			UIKeyCommand(action: #selector(arrowUp(_:)), input: UIKeyCommand.inputUpArrow),
			UIKeyCommand(action: #selector(arrowDown(_:)), input: UIKeyCommand.inputDownArrow),
			UIKeyCommand(action: #selector(cancel(_:)), input: UIKeyCommand.inputEscape),
			UIKeyCommand(action: #selector(submit(_:)), input: "\r"),
		]
	}

	@IBOutlet weak var textTextField: SearchTextField!
	@IBOutlet weak var linkTextField: UITextField!

	@IBOutlet weak var newOutlineButton: UIButton!
	@IBOutlet weak var submitButton: UIButton!

	weak var delegate: LinkViewControllerDelegate?
	var cursorCoordinates: CursorCoordinates?
	var text: String?
	var link: String?
	var range: NSRange?
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		submitButton.role = .primary
		textTextField.text = text
		linkTextField.text = link

		textTextField.delegate = self
		linkTextField.delegate = self
		textTextField.maxResultsListHeight = 80
		
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

	@IBAction func newOutline(_ sender: Any) {
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

extension MacLinkViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textTextField.isSelecting {
			textTextField.activateSelection()
		} else {
			submitAndDismiss()
		}
		return false
	}
	
}

// MARK: Helpers

private extension MacLinkViewController {
	
	@objc func textDidChange(_ note: Notification) {
		updateUI()
	}
	
	func updateUI() {
		newOutlineButton.isEnabled = !(textTextField.text?.isEmpty ?? true) && (linkTextField.text?.isEmpty ?? true)
	}
	
	func submitAndDismiss() {
		guard !textTextField.isSelecting else {
			textTextField.activateSelection()
			return
		}
		
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
