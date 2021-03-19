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
			UIKeyCommand(action: #selector(arrowDown(_:)), input: UIKeyCommand.inputDownArrow)
		]
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		searchTextField.delegate = self
		
		searchTextField.itemSelectionHandler = { [weak self] (filteredResults: [SearchTextFieldItem], index: Int) in
			guard let self = self, let documentID = filteredResults[index].associatedObject as? EntityID else {
				return
			}
			self.sceneDelegate?.closeWindow()
			appDelegate.openDocument(documentID)
		}

		let searchItems = AccountManager.shared.documents.map { SearchTextFieldItem(title: $0.title ?? "", associatedObject: $0.id) }
		searchTextField.filterItems(searchItems)
	}

	override func viewDidAppear(_ animated: Bool) {
		#if targetEnvironment(macCatalyst)
		appDelegate.appKitPlugin?.configureOpenQuickly(view.window?.nsWindow)
		#endif
		searchTextField.becomeFirstResponder()
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
	}
}

extension MacOpenQuicklyViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		searchTextField.activateSelection()
		return false
	}
	
}
