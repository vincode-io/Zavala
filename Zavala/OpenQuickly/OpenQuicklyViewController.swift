//
//  OpenQuicklyViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/13/21.
//

import UIKit
import VinOutlineKit

@MainActor
protocol OpenQuicklyViewControllerDelegate: AnyObject {
	func quicklyOpenDocument(documentID: EntityID)
}

class OpenQuicklyViewController: UITableViewController {

	weak var delegate: OpenQuicklyViewControllerDelegate?

	@IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
	@IBOutlet weak var searchTextField: SearchTextField!
	
	override func viewDidLoad() {
        super.viewDidLoad()

		searchTextField.delegate = self

		searchTextField.placeholder = .openQuicklySearchPlaceholder
		searchTextField.inlineMode = true

		searchTextField.itemSelectionHandler = { [weak self] (filteredResults: [SearchTextFieldItem], index: Int) in
			guard let self, let documentID = filteredResults[index].associatedObject as? EntityID else {
				return
			}
			self.delegate?.quicklyOpenDocument(documentID: documentID)
			self.dismiss(animated: true)
		}
		
		searchTextField.userStoppedTypingHandler = { [weak self] in
			self?.doneBarButtonItem.isEnabled = self?.searchTextField.isShowingResults ?? false
		}
		
		let searchItems = AccountManager.shared.activeDocuments.map { SearchTextFieldItem(title: $0.title ?? "", associatedObject: $0.id) }
		searchTextField.filterItems(searchItems)
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		searchTextField.becomeFirstResponder()
	}
	
	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func submit(_ sender: Any) {
		searchTextField.textFieldDidEndEditingOnExit()
	}
	
}

// MARK: UITextFieldDelegate

extension OpenQuicklyViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		searchTextField.textFieldDidEndEditingOnExit()
		return false
	}
	
}
