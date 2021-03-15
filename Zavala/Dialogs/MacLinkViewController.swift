//
//  LinkViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 12/17/20.
//

import UIKit
import RSCore
import Templeton

class MacLinkViewController: MacFormViewController {

	@IBOutlet weak var textTextField: SearchTextField!
	@IBOutlet weak var linkTextField: UITextField!

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

		textTextField.itemSelectionHandler = { [weak self] (filteredResults: [SearchTextFieldItem], index: Int) in
			guard let self = self, let documentID = filteredResults[index].associatedObject as? EntityID else {
				return
			}
			self.textTextField.text = filteredResults[index].title
			self.linkTextField.text = documentID.url.absoluteString
		}
		
		let searchItems = AccountManager.shared.documents.map { SearchTextFieldItem(title: $0.title ?? "", associatedObject: $0.id) }
		textTextField.filterItems(searchItems)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		textTextField.becomeFirstResponder()
	}
	
	@IBAction override func submit(_ sender: Any) {
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
