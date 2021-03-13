//
//  OpenQuicklyViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/13/21.
//

import UIKit
import Templeton

protocol OpenQuicklyViewControllerDelegate: AnyObject {
	func openDocument(_: OpenQuicklyViewController, documentID: EntityID)
}

class OpenQuicklyViewController: MacFormViewController {

	weak var delegate: OpenQuicklyViewControllerDelegate?
	
	@IBOutlet weak var searchTextField: SearchTextField!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		searchTextField.placeholder = L10n.openQuicklyPlaceholder
		searchTextField.autocorrectionType = .no
		searchTextField.inlineMode = true

		searchTextField.itemSelectionHandler = { [weak self] (filteredResults: [SearchTextFieldItem], index: Int) in
			guard let self = self, let documentID = filteredResults[index].associatedObject as? EntityID else {
				return
			}
			self.delegate?.openDocument(self, documentID: documentID)
			self.dismiss(animated: true)
		}
		
		let searchItems = AccountManager.shared.documents.map { SearchTextFieldItem(title: $0.title ?? "", associatedObject: $0.id) }
		searchTextField.filterItems(searchItems)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		searchTextField.becomeFirstResponder()
	}
	
	override func submit(_ sender: Any) {
		searchTextField.textFieldDidEndEditingOnExit()
	}

}
