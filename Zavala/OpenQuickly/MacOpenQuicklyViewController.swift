//
//  MacOpenQuicklyViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/19/21.
//

import UIKit
import Templeton

class MacOpenQuicklyViewController: UIViewController {

	@IBOutlet weak var searchTextField: SearchTextField!
	@IBOutlet weak var openButton: UIButton!
	
	weak var sceneDelegate: MacOpenQuicklySceneDelegate?

	override var keyCommands: [UIKeyCommand]? {
		[
			UIKeyCommand(action: #selector(arrowUp(_:)), input: UIKeyCommand.inputUpArrow),
			UIKeyCommand(action: #selector(arrowDown(_:)), input: UIKeyCommand.inputDownArrow),
			UIKeyCommand(action: #selector(cancel(_:)), input: UIKeyCommand.inputEscape)
		]
	}

	private var collectionsViewController: MacOpenQuicklyCollectionsViewController? {
		return children.first(where: { $0 is MacOpenQuicklyCollectionsViewController }) as? MacOpenQuicklyCollectionsViewController
	}
	
	private var documentsViewController: MacOpenQuicklyDocumentsViewController? {
		return children.first(where: { $0 is MacOpenQuicklyDocumentsViewController }) as? MacOpenQuicklyDocumentsViewController
	}

	private var selectedDocumentID: EntityID?

    override func viewDidLoad() {
        super.viewDidLoad()
		
		collectionsViewController?.delegate = self
		documentsViewController?.delegate = self

		searchTextField.delegate = self
		searchTextField.layer.borderWidth = 1
		searchTextField.layer.borderColor = UIColor.systemGray2.cgColor
		searchTextField.layer.cornerRadius = 3
		
		searchTextField.itemSelectionHandler = { [weak self] (filteredResults: [SearchTextFieldItem], index: Int) in
			guard let self = self, let documentID = filteredResults[index].associatedObject as? EntityID else {
				return
			}
			self.openDocument(documentID)
		}

		let searchItems = AccountManager.shared.activeDocuments.map { SearchTextFieldItem(title: $0.title ?? "", associatedObject: $0.id) }
		searchTextField.filterItems(searchItems)
	}

	override func viewDidAppear(_ animated: Bool) {
		#if targetEnvironment(macCatalyst)
		appDelegate.appKitPlugin?.configureOpenQuickly(view.window?.nsWindow)
		#endif
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.searchTextField.becomeFirstResponder()
		}
	}
	
	@objc func arrowUp(_ sender: Any) {
		searchTextField.selectAbove()
	}

	@objc func arrowDown(_ sender: Any) {
		searchTextField.selectBelow()
	}

	@IBAction func newOutline(_ sender: Any) {
		sceneDelegate?.closeWindow()
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.newOutline)
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
	}
	
	@IBAction func cancel(_ sender: Any) {
		sceneDelegate?.closeWindow()
	}
	
	@IBAction func submit(_ sender: Any) {
		guard let documentID = selectedDocumentID else { return }
		openDocument(documentID)
	}
	
}

extension MacOpenQuicklyViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		searchTextField.activateSelection()
		return false
	}
	
}

// MARK: MacOpenQuicklyCollectionsDelegate

extension MacOpenQuicklyViewController: MacOpenQuicklyCollectionsDelegate {
	
	func documentContainerSelectionDidChange(_: MacOpenQuicklyCollectionsViewController, documentContainer: DocumentContainer?) {
		documentsViewController?.setDocumentContainer(documentContainer)
	}
	
}

// MARK: MacOpenQuicklyDocumentsDelegate

extension MacOpenQuicklyViewController: MacOpenQuicklyDocumentsDelegate {
	
	func documentSelectionDidChange(_: MacOpenQuicklyDocumentsViewController, documentID: EntityID?) {
		selectedDocumentID = documentID
		updateUI()
	}
	
	func openDocument(_: MacOpenQuicklyDocumentsViewController, documentID: EntityID) {
		openDocument(documentID)
	}
	
}

// MARK: Helpers

extension MacOpenQuicklyViewController {
	
	private func updateUI() {
		openButton.isEnabled = selectedDocumentID != nil
	}
	
	private func openDocument(_ documentID: EntityID) {
		self.sceneDelegate?.closeWindow()
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
		activity.userInfo = [Pin.UserInfoKeys.pin: Pin(documentID: documentID).userInfo]
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
	}
	
}
